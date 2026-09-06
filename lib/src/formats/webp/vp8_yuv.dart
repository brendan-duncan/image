/// RGB to YUV 4:2:0 conversion, the first step of lossy encoding.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../color/channel_order.dart';
import '../../color/format.dart';
import '../../image/image.dart';
import '../../image/image_data_uint8.dart';
import '../../util/_internal.dart';

/// A picture in the planar form VP8 codes: full-resolution luma, chroma at
/// half resolution in both directions, and alpha kept aside at full resolution.
@internal
class VP8Yuv {
  VP8Yuv(this.width, this.height, this.y, this.u, this.v, this.a);

  final int width;
  final int height;

  /// Luma, `width * height`, one byte per pixel.
  final Uint8List y;

  /// Chroma, `uvWidth * uvHeight` each.
  final Uint8List u;
  final Uint8List v;

  /// Alpha at full resolution, or null when the picture is opaque.
  final Uint8List? a;

  int get uvWidth => (width + 1) >> 1;
  int get uvHeight => (height + 1) >> 1;
}

// Fixed-point precision of the RGB->YUV matrix.
const _yuvFix = 16;
const _yuvHalf = 1 << (_yuvFix - 1);

// Chroma is averaged in a lightly compressed space rather than on the raw
// bytes: averaging gamma-encoded values darkens edges, and at 4:2:0 that shows
// up as a colour shift along every hard boundary. libwebp uses an exponent of
// 0.80 with a 12-bit linear representation.
const _gammaFix = 12; // fixed-point precision of a linear value
const _gammaTabFix = 7; // fractional bits of the table index
const _gammaTabSize = 1 << (_gammaFix - _gammaTabFix);
const _gammaScale = (1 << _gammaFix) - 1;
const _gammaTabRounder = 1 << (_gammaTabFix - 1);
const _gamma = 0.80;

// (1 << _alphaFix) / a, so the alpha-weighted average is a multiply and a
// shift. The factor of four that turns a 2x2 sum into a scaled average is
// folded into the shift.
const _alphaFix = 19;

final _gammaToLinear = () {
  final table = Uint16List(256);
  for (var v = 0; v <= 255; v++) {
    table[v] = (math.pow(v / 255, _gamma) * _gammaScale + 0.5).toInt();
  }
  return table;
}();

final _linearToGamma = () {
  final table = Int32List(_gammaTabSize + 1);
  const scale = (1 << _gammaTabFix) / _gammaScale;
  for (var v = 0; v <= _gammaTabSize; v++) {
    table[v] = (255 * math.pow(scale * v, 1 / _gamma) + 0.5).toInt();
  }
  return table;
}();

final _invAlpha = () {
  final table = Int32List(4 * 0xff + 1);
  for (var a = 1; a < table.length; a++) {
    table[a] = (1 << _alphaFix) ~/ a;
  }
  return table;
}();

/// Converts a sum of up to four linear values back to gamma space, keeping the
/// factor of four in the result (so the output is scaled by 4).
@pragma('vm:prefer-inline')
int _toGamma(int sum, int shift) {
  final v = sum << shift;
  final pos = v >> (_gammaTabFix + 2);
  final x = v & ((1 << (_gammaTabFix + 2)) - 1);
  final v0 = _linearToGamma[pos];
  final v1 = _linearToGamma[pos + 1];
  return (v1 * x + v0 * ((1 << (_gammaTabFix + 2)) - x) + _gammaTabRounder) >>
      _gammaTabFix;
}

@pragma('vm:prefer-inline')
int _rgbToY(int r, int g, int b) =>
    (16839 * r + 33059 * g + 6420 * b + _yuvHalf + (16 << _yuvFix)) >> _yuvFix;

/// Clips a chroma value given at [_yuvFix] + 2 precision.
@pragma('vm:prefer-inline')
int _clipUV(int uv) {
  final v = (uv + (_yuvHalf << 2) + (128 << (_yuvFix + 2))) >> (_yuvFix + 2);
  return v & ~0xff == 0
      ? v
      : v < 0
          ? 0
          : 255;
}

/// Converts [image] to the planes VP8 codes.
///
/// Chroma is the average of each 2x2 block, weighted by alpha where the block
/// is partly transparent so that the colour of invisible pixels cannot bleed
/// into visible ones.
@internal
VP8Yuv importYuv(Image image) {
  final width = image.width;
  final height = image.height;
  final uvWidth = (width + 1) >> 1;
  final uvHeight = (height + 1) >> 1;

  final rgba = _rgbaBytes(image);
  final y = Uint8List(width * height);
  final u = Uint8List(uvWidth * uvHeight);
  final v = Uint8List(uvWidth * uvHeight);

  var hasAlpha = false;
  if (image.hasAlpha) {
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] != 0xff) {
        hasAlpha = true;
        break;
      }
    }
  }
  Uint8List? a;
  if (hasAlpha) {
    a = Uint8List(width * height);
    for (var i = 0, j = 3; i < a.length; i++, j += 4) {
      a[i] = rgba[j];
    }
  }

  final stride = 4 * width;
  // Accumulated 2x2 sums, as r, g, b, alpha per chroma sample.
  final tmp = Int32List(4 * uvWidth);

  var row = 0;
  var uvRow = 0;
  for (; row + 1 < height; row += 2, uvRow++) {
    final top = row * stride;
    _rowToY(rgba, top, y, row * width, width);
    _rowToY(rgba, top + stride, y, (row + 1) * width, width);
    if (hasAlpha && _rowsHaveAlpha(rgba, top, width, 2, stride)) {
      _accumulateRGBA(rgba, top, stride, tmp, width);
    } else {
      _accumulateRGB(rgba, top, stride, tmp, width);
    }
    _rowsToUV(tmp, u, v, uvRow * uvWidth, uvWidth);
  }
  if (row < height) {
    // Odd last row: the 2x2 block degenerates to 1x2, so the pair sum is
    // doubled to stay on the same scale.
    final top = row * stride;
    _rowToY(rgba, top, y, row * width, width);
    if (hasAlpha && _rowsHaveAlpha(rgba, top, width, 1, stride)) {
      _accumulateRGBA(rgba, top, 0, tmp, width);
    } else {
      _accumulateRGB(rgba, top, 0, tmp, width);
    }
    _rowsToUV(tmp, u, v, uvRow * uvWidth, uvWidth);
  }

  return VP8Yuv(width, height, y, u, v, a);
}

/// Size of the block the transparent-area cleanup works on.
const _cleanupBlock = 8;

/// Replaces what sits under transparent pixels with something cheaper to code.
///
/// The colour beneath a fully transparent pixel is invisible, but the encoder
/// still pays for every edge in it. Within a block that is partly transparent
/// the hidden luma is set to the average of the visible luma, which removes
/// those edges; a run of blocks that are transparent throughout is flattened
/// to one colour, which removes them entirely.
///
/// libwebp does the same in `WebPCleanupTransparentArea` unless given
/// `-exact`.
@internal
void cleanupTransparentArea(VP8Yuv pic) {
  final a = pic.a;
  if (a == null) {
    return;
  }
  final width = pic.width;
  final height = pic.height;
  final uvStride = pic.uvWidth;
  const size = _cleanupBlock;
  const half = size ~/ 2;

  var y = 0;
  for (; y + size <= height; y += size) {
    var needReset = true;
    var yv = 0;
    var uv = 0;
    var vv = 0;
    var x = 0;
    for (; x + size <= width; x += size) {
      final yOff = y * width + x;
      final uvOff = (y >> 1) * uvStride + (x >> 1);
      if (_smoothenBlock(a, pic.y, yOff, width, size, size)) {
        if (needReset) {
          yv = pic.y[yOff];
          uv = pic.u[uvOff];
          vv = pic.v[uvOff];
          needReset = false;
        }
        _flatten(pic.y, yOff, yv, width, size);
        _flatten(pic.u, uvOff, uv, uvStride, half);
        _flatten(pic.v, uvOff, vv, uvStride, half);
      } else {
        needReset = true;
      }
    }
    if (x < width) {
      _smoothenBlock(a, pic.y, y * width + x, width, width - x, size);
    }
  }
  if (y < height) {
    final subHeight = height - y;
    var x = 0;
    for (; x + size <= width; x += size) {
      _smoothenBlock(a, pic.y, y * width + x, width, size, subHeight);
    }
    if (x < width) {
      _smoothenBlock(a, pic.y, y * width + x, width, width - x, subHeight);
    }
  }
}

/// Flattens the luma of the transparent pixels in one block to the average of
/// the visible ones. Returns true if the block has no visible pixel at all.
bool _smoothenBlock(
    Uint8List a, Uint8List luma, int off, int stride, int width, int height) {
  var sum = 0;
  var count = 0;
  for (var y = 0; y < height; y++) {
    final row = off + y * stride;
    for (var x = 0; x < width; x++) {
      if (a[row + x] != 0) {
        count++;
        sum += luma[row + x];
      }
    }
  }
  if (count > 0 && count < width * height) {
    final avg = sum ~/ count;
    for (var y = 0; y < height; y++) {
      final row = off + y * stride;
      for (var x = 0; x < width; x++) {
        if (a[row + x] == 0) {
          luma[row + x] = avg;
        }
      }
    }
  }
  return count == 0;
}

void _flatten(Uint8List plane, int off, int value, int stride, int size) {
  for (var y = 0; y < size; y++) {
    plane.fillRange(off + y * stride, off + y * stride + size, value);
  }
}

/// The picture as interleaved RGBA bytes.
///
/// The general path converts pixel by pixel through the colour machinery,
/// which showed up in the profile at several percent of the whole encode. An
/// 8-bit image is already stored interleaved in the order wanted, so it needs
/// at most a widening pass, and a four-channel one needs nothing at all.
Uint8List _rgbaBytes(Image image) {
  final data = image.data;
  if (image.format == Format.uint8 &&
      image.palette == null &&
      data is ImageDataUint8) {
    final src = data.data;
    final pixels = image.width * image.height;
    switch (image.numChannels) {
      case 4:
        return src;
      case 3:
        final out = Uint8List(pixels * 4);
        for (var i = 0, j = 0; i < pixels; i++, j += 3) {
          final o = i * 4;
          out[o] = src[j];
          out[o + 1] = src[j + 1];
          out[o + 2] = src[j + 2];
          out[o + 3] = 0xff;
        }
        return out;
      case 1:
        final out = Uint8List(pixels * 4);
        for (var i = 0; i < pixels; i++) {
          final v = src[i];
          final o = i * 4;
          out[o] = v;
          out[o + 1] = v;
          out[o + 2] = v;
          out[o + 3] = 0xff;
        }
        return out;
    }
  }
  return image
      .convert(format: Format.uint8, numChannels: 4, alpha: 255)
      .getBytes(order: ChannelOrder.rgba);
}

void _rowToY(Uint8List rgba, int src, Uint8List y, int dst, int width) {
  for (var i = 0; i < width; i++, src += 4) {
    y[dst + i] = _rgbToY(rgba[src], rgba[src + 1], rgba[src + 2]);
  }
}

bool _rowsHaveAlpha(Uint8List rgba, int src, int width, int rows, int stride) {
  for (var r = 0; r < rows; r++, src += stride) {
    for (var i = src + 3, end = src + 4 * width; i < end; i += 4) {
      if (rgba[i] != 0xff) {
        return true;
      }
    }
  }
  return false;
}

/// Averages each 2x2 block in linear space. [stride] is zero on the last row of
/// an odd-height image, which makes every read hit the same row twice.
void _accumulateRGB(
    Uint8List rgba, int src, int stride, Int32List dst, int width) {
  final toLinear = _gammaToLinear;
  var i = 0;
  var j = src;
  for (; i < (width >> 1); i++, j += 8) {
    final k = j + stride;
    dst[4 * i] = _toGamma(
        toLinear[rgba[j]] +
            toLinear[rgba[j + 4]] +
            toLinear[rgba[k]] +
            toLinear[rgba[k + 4]],
        0);
    dst[4 * i + 1] = _toGamma(
        toLinear[rgba[j + 1]] +
            toLinear[rgba[j + 5]] +
            toLinear[rgba[k + 1]] +
            toLinear[rgba[k + 5]],
        0);
    dst[4 * i + 2] = _toGamma(
        toLinear[rgba[j + 2]] +
            toLinear[rgba[j + 6]] +
            toLinear[rgba[k + 2]] +
            toLinear[rgba[k + 6]],
        0);
  }
  if (width & 1 != 0) {
    final k = j + stride;
    dst[4 * i] = _toGamma(toLinear[rgba[j]] + toLinear[rgba[k]], 1);
    dst[4 * i + 1] = _toGamma(toLinear[rgba[j + 1]] + toLinear[rgba[k + 1]], 1);
    dst[4 * i + 2] = _toGamma(toLinear[rgba[j + 2]] + toLinear[rgba[k + 2]], 1);
  }
}

/// As [_accumulateRGB], but weights each pixel by its alpha, so that the colour
/// stored under a transparent pixel does not pull the visible average.
void _accumulateRGBA(
    Uint8List rgba, int src, int stride, Int32List dst, int width) {
  var i = 0;
  var j = src;
  for (; i < (width >> 1); i++, j += 8) {
    final k = j + stride;
    final a = rgba[j + 3] + rgba[j + 7] + rgba[k + 3] + rgba[k + 7];
    if (a == 4 * 0xff || a == 0) {
      _accumulate4(rgba, j, k, dst, 4 * i);
    } else {
      dst[4 * i] = _weighted(rgba, j, k, 4, a, 0);
      dst[4 * i + 1] = _weighted(rgba, j, k, 4, a, 1);
      dst[4 * i + 2] = _weighted(rgba, j, k, 4, a, 2);
    }
    dst[4 * i + 3] = a;
  }
  if (width & 1 != 0) {
    final k = j + stride;
    final a = 2 * (rgba[j + 3] + rgba[k + 3]);
    if (a == 4 * 0xff || a == 0) {
      final toLinear = _gammaToLinear;
      dst[4 * i] = _toGamma(toLinear[rgba[j]] + toLinear[rgba[k]], 1);
      dst[4 * i + 1] =
          _toGamma(toLinear[rgba[j + 1]] + toLinear[rgba[k + 1]], 1);
      dst[4 * i + 2] =
          _toGamma(toLinear[rgba[j + 2]] + toLinear[rgba[k + 2]], 1);
    } else {
      dst[4 * i] = _weighted(rgba, j, k, 0, a, 0);
      dst[4 * i + 1] = _weighted(rgba, j, k, 0, a, 1);
      dst[4 * i + 2] = _weighted(rgba, j, k, 0, a, 2);
    }
    dst[4 * i + 3] = a;
  }
}

@pragma('vm:prefer-inline')
void _accumulate4(Uint8List rgba, int j, int k, Int32List dst, int at) {
  final toLinear = _gammaToLinear;
  for (var c = 0; c < 3; c++) {
    dst[at + c] = _toGamma(
        toLinear[rgba[j + c]] +
            toLinear[rgba[j + 4 + c]] +
            toLinear[rgba[k + c]] +
            toLinear[rgba[k + 4 + c]],
        0);
  }
}

/// The alpha-weighted linear average of one channel over a 2x2 block, back in
/// gamma space. [step] is 0 for the half block of an odd-width image.
@pragma('vm:prefer-inline')
int _weighted(Uint8List rgba, int j, int k, int step, int a, int c) {
  final toLinear = _gammaToLinear;
  final sum = rgba[j + 3] * toLinear[rgba[j + c]] +
      rgba[j + step + 3] * toLinear[rgba[j + step + c]] +
      rgba[k + 3] * toLinear[rgba[k + c]] +
      rgba[k + step + 3] * toLinear[rgba[k + step + c]];
  return _toGamma((sum * _invAlpha[a]) >> (_alphaFix - 2), 0);
}

void _rowsToUV(Int32List rgb, Uint8List u, Uint8List v, int dst, int width) {
  for (var i = 0; i < width; i++) {
    final r = rgb[4 * i];
    final g = rgb[4 * i + 1];
    final b = rgb[4 * i + 2];
    u[dst + i] = _clipUV(-9719 * r - 19081 * g + 28800 * b);
    v[dst + i] = _clipUV(28800 * r - 24116 * g - 4684 * b);
  }
}
