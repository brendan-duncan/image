import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/color_util.dart';
import '../util/math_util.dart';

/// Convert the image to grayscale.
Image grayscale(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    if (frame.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        final l = getLuminanceRgb(p.getRed(i), p.getGreen(i), p.getBlue(i));
        if (amount != 1) {
          final r = mix(p.getRed(i), l, amount);
          final g = mix(p.getGreen(i), l, amount);
          final b = mix(p.getBlue(i), l, amount);
          p
            ..setRed(i, r)
            ..setGreen(i, g)
            ..setBlue(i, b);
        } else {
          p
            ..setRed(i, l)
            ..setGreen(i, l)
            ..setBlue(i, l);
        }
      }
    } else if (mask == null &&
        frame.format == Format.uint8 &&
        frame.numChannels >= 3) {
      _grayscaleUint8(frame.toUint8List(), frame.numChannels, amount);
    } else {
      for (final p in frame) {
        final l = getLuminanceRgb(p.r, p.g, p.b);
        final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
        final mx = (msk ?? 1) * amount;
        if (mx != 1) {
          p
            ..r = mix(p.r, l, mx)
            ..g = mix(p.g, l, mx)
            ..b = mix(p.b, l, mx);
        } else {
          p
            ..r = l
            ..g = l
            ..b = l;
        }
      }
    }
  }

  return src;
}

// A fast path for RGB(A) uint8 images, computing the same values as the
// generic path.
void _grayscaleUint8(Uint8List data, int nc, num amount) {
  final a = amount.toDouble();
  final n = data.length;
  if (a == 1) {
    // The weights sum to 1, so l is within [0, 255] and needs no clamping.
    for (var i = 0; i < n; i += nc) {
      final l =
          (0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]).toInt();
      data[i] = l;
      data[i + 1] = l;
      data[i + 2] = l;
    }
    return;
  }
  final ia = 1 - a;
  for (var i = 0; i < n; i += nc) {
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];
    final l = 0.299 * r + 0.587 * g + 0.114 * b;
    data[i] = (r * ia + l * a).clamp(0, 255).toInt();
    data[i + 1] = (g * ia + l * a).clamp(0, 255).toInt();
    data[i + 2] = (b * ia + l * a).clamp(0, 255).toInt();
  }
}
