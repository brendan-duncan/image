import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_float32.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../image/image_data_float32.dart';
import '../image/image_data_uint8.dart';
import 'color_util.dart';

// Operations that average colors, such as blurring and resizing, can
// optionally average the light the colors represent rather than their stored
// sRGB values. They do so on a float32 working copy of the image holding
// linear values, made with [linearRgbCopy], and convert the result back with
// [srgbCopy] or [writeSrgb]. Alpha is a coverage, not a color, so it's copied
// as is.

// sRGB uint8 value -> linear light.
final Float32List _toLinear8 = Float32List.fromList(
    List<double>.generate(256, (v) => srgbToLinear(v / 255)));

// _midpoints8[k] is the linear value halfway, in sRGB, between the uint8
// values k and k + 1, so a linear value encodes to the number of midpoints
// below it: the nearest uint8 value. That makes uint8 -> linear -> uint8
// exact.
final Float64List _midpoints8 = Float64List.fromList(
    List<double>.generate(255, (k) => srgbToLinear((k + 0.5) / 255)));

int _linearToSrgb8(double v) {
  var lo = 0;
  var hi = 255;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (v > _midpoints8[mid]) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

int _alphaChannel(int numChannels) =>
    numChannels == 2 || numChannels == 4 ? numChannels - 1 : -1;

Image _emptyLike(Image frame, Format format, int numChannels) => Image(
    width: frame.width,
    height: frame.height,
    format: format,
    numChannels: numChannels,
    exif: frame.hasExif ? frame.exif.clone() : null,
    iccp: frame.iccProfile?.clone(),
    backgroundColor: frame.backgroundColor?.clone(),
    frameType: frame.frameType,
    loopCount: frame.loopCount,
    frameDuration: frame.frameDuration)
  ..textData =
      frame.textData != null ? Map<String, String>.from(frame.textData!) : null;

/// Returns [c], taken as sRGB, as a float32 color holding linear light, for
/// use with an image made by [linearRgbCopy].
Color? linearColor(Color? c) => c == null
    ? null
    : ColorFloat32.rgba(
        srgbToLinear(c.rNormalized),
        srgbToLinear(c.gNormalized),
        srgbToLinear(c.bNormalized),
        c.aNormalized);

/// Returns a float32 copy of [src], with its colors, taken as sRGB, converted
/// to normalized linear light. A palette is expanded. With [noAnimation], only
/// the first frame is copied.
Image linearRgbCopy(Image src, {bool noAnimation = false}) {
  Image? first;
  for (final frame in noAnimation ? [src] : src.frames) {
    final nc = frame.numChannels;
    final alpha = _alphaChannel(nc);
    final out = _emptyLike(frame, Format.float32, nc);
    final dst = (out.data! as ImageDataFloat32).data;
    final data = frame.data;
    if (data is ImageDataUint8 && !frame.hasPalette) {
      final bytes = data.data;
      final n = frame.width * frame.height * nc;
      for (var i = 0, c = 0; i < n; ++i) {
        final v = bytes[i];
        dst[i] = c == alpha ? v / 255 : _toLinear8[v];
        if (++c == nc) {
          c = 0;
        }
      }
    } else {
      var i = 0;
      for (final p in frame) {
        final max = p.maxChannelValue;
        for (var c = 0; c < nc; ++c, ++i) {
          final v = p[c] / max;
          dst[i] = c == alpha ? v : srgbToLinear(v);
        }
      }
    }
    if (first == null) {
      first = out;
    } else {
      first.addFrame(out);
    }
  }
  return first!;
}

/// Runs [filter], which modifies an image in place, on a linear light copy of
/// [src] and writes the result back into [src]. Returns [src], or for an
/// image with a palette, which can't hold the result, a new image.
Image filterLinear(Image src, Image Function(Image linear) filter) {
  final linear = filter(linearRgbCopy(src));
  if (src.hasPalette) {
    return srgbCopy(linear, src.format);
  }
  writeSrgb(linear, src);
  return src;
}

/// Returns a copy of [linear], made by [linearRgbCopy] or an operation on such
/// a copy, with its colors converted back to sRGB and stored as [format].
Image srgbCopy(Image linear, Format format) {
  Image? first;
  for (final frame in linear.frames) {
    final out = _emptyLike(frame, format, frame.numChannels);
    writeSrgbFrame(frame, out);
    if (first == null) {
      first = out;
    } else {
      first.addFrame(out);
    }
  }
  return first!;
}

/// Writes [linear], made by [linearRgbCopy] from [dst], back into [dst], with
/// its colors converted back to sRGB. [dst] must not have a palette.
void writeSrgb(Image linear, Image dst) {
  for (var i = 0; i < dst.numFrames; ++i) {
    writeSrgbFrame(linear.frames[i], dst.frames[i]);
  }
}

/// Writes the single frame [linear] into the frame [dst], which has the same
/// size and number of channels, with its colors converted back to sRGB.
void writeSrgbFrame(Image linear, Image dst) {
  final nc = linear.numChannels;
  final alpha = _alphaChannel(nc);
  final src = (linear.data! as ImageDataFloat32).data;
  final data = dst.data;
  if (data is ImageDataUint8) {
    final bytes = data.data;
    final n = linear.width * linear.height * nc;
    for (var i = 0, c = 0; i < n; ++i) {
      final v = src[i];
      bytes[i] =
          c == alpha ? (v * 255).round().clamp(0, 255) : _linearToSrgb8(v);
      if (++c == nc) {
        c = 0;
      }
    }
    return;
  }
  final type = dst.formatType;
  final isFloat = type == FormatType.float;
  final lo = type == FormatType.int ? -1.0 : 0.0;
  var i = 0;
  for (final p in dst) {
    final max = p.maxChannelValue;
    for (var c = 0; c < nc; ++c, ++i) {
      var v = src[i].toDouble();
      if (c != alpha) {
        v = linearToSrgb(v);
      }
      p[c] = isFloat ? v * max : (v.clamp(lo, 1.0) * max).round();
    }
  }
}
