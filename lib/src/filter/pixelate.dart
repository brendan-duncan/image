import 'dart:typed_data';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/_linear_rgb.dart';
import '../util/math_util.dart';

enum PixelateMode {
  /// Use the top-left pixel of a block for the block color.
  upperLeft,

  /// Use the average of the pixels within a block for the block color.
  average
}

/// Pixelate the [src] image.
///
/// [size] determines the size of the pixelated blocks.
/// If [mode] is [PixelateMode.upperLeft] then the upper-left corner of the
/// block will be used for the block color. Otherwise if [mode] is
/// [PixelateMode.average], the average of all the pixels in the block will be
/// used for the block color.
///
/// If [linearBlend] is true, the colors, taken as sRGB, are averaged and mixed
/// as linear light, which is slower but keeps the blocks from darkening.
Image pixelate(Image src,
    {required int size,
    PixelateMode mode = PixelateMode.upperLeft,
    num amount = 1,
    bool linearBlend = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (size <= 1) {
    return src;
  }
  if (linearBlend) {
    return filterLinear(
        src,
        (linear) => pixelate(linear,
            size: size,
            mode: mode,
            amount: amount,
            mask: mask,
            maskChannel: maskChannel));
  }
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    final w = frame.width;
    final h = frame.height;
    switch (mode) {
      case PixelateMode.upperLeft:
        for (final p in frame) {
          final x2 = (p.x ~/ size) * size;
          final y2 = (p.y ~/ size) * size;
          final p2 = frame.getPixel(x2, y2);
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          final mx = (msk ?? 1) * amount;
          if (mx == 1) {
            p.set(p2);
          } else {
            p
              ..r = mix(p.r, p2.r, mx)
              ..g = mix(p.g, p2.g, mx)
              ..b = mix(p.b, p2.b, mx)
              ..a = mix(p.a, p2.a, mx);
          }
        }
        break;
      case PixelateMode.average:
        // Average each block from the original pixels before any are
        // overwritten. Partial blocks at the right and bottom edges are
        // averaged over the pixels they contain.
        final bw = (w + size - 1) ~/ size;
        final bh = (h + size - 1) ~/ size;
        final sums = Float64List(bw * bh * 4);
        final counts = Int32List(bw * bh);
        for (final p in frame) {
          final bi = (p.y ~/ size) * bw + (p.x ~/ size);
          final si = bi * 4;
          sums[si] += p.r;
          sums[si + 1] += p.g;
          sums[si + 2] += p.b;
          sums[si + 3] += p.a;
          counts[bi]++;
        }
        for (var bi = 0, si = 0; bi < counts.length; ++bi, si += 4) {
          final total = counts[bi];
          sums[si] /= total;
          sums[si + 1] /= total;
          sums[si + 2] /= total;
          sums[si + 3] /= total;
        }
        for (final p in frame) {
          final si = ((p.y ~/ size) * bw + (p.x ~/ size)) * 4;
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          final mx = (msk ?? 1) * amount;
          p
            ..r = mix(p.r, sums[si], mx)
            ..g = mix(p.g, sums[si + 1], mx)
            ..b = mix(p.b, sums[si + 2], mx)
            ..a = mix(p.a, sums[si + 3], mx);
        }
        break;
    }
  }
  return src;
}
