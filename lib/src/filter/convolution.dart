import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply a 3x3 convolution filter to the [src] image. [filter] should be a
/// list of 9 numbers.
///
/// The rgb channels will be divided by [div] and add [offset], allowing
/// filters to normalize and offset the filtered pixel value.
Image convolution(Image src,
    {required List<num> filter,
    num div = 1.0,
    num offset = 0.0,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  if (mask == null &&
      src.format == Format.uint8 &&
      src.numChannels >= 3 &&
      filter.length >= 9) {
    for (final frame in src.frames) {
      _convolutionUint8(frame, filter, div, offset, amount);
    }
    return src;
  }
  final tmp = Image.from(src);
  for (final frame in src.frames) {
    final tmpFrame = tmp.frames[frame.frameIndex];
    for (final c in tmpFrame) {
      num r = 0.0;
      num g = 0.0;
      num b = 0.0;
      for (var j = 0, fi = 0; j < 3; ++j) {
        final yv = min(max(c.y - 1 + j, 0), src.height - 1);
        for (var i = 0; i < 3; ++i, ++fi) {
          final xv = min(max(c.x - 1 + i, 0), src.width - 1);
          final c2 = tmpFrame.getPixel(xv, yv);
          r += c2.r * filter[fi];
          g += c2.g * filter[fi];
          b += c2.b * filter[fi];
        }
      }

      r = ((r / div) + offset).clamp(0, 255);
      g = ((g / div) + offset).clamp(0, 255);
      b = ((b / div) + offset).clamp(0, 255);

      final p = frame.getPixel(c.x, c.y);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, r, mx)
        ..g = mix(p.g, g, mx)
        ..b = mix(p.b, b, mx);
    }
  }

  return src;
}

// A fast path for RGB(A) uint8 images, computing the same values as the
// general path. Rows are filtered in place, keeping copies of the original
// rows above; the row below hasn't been written yet.
void _convolutionUint8(
    Image frame, List<num> filter, num div, num offset, num amount) {
  final w = frame.width;
  final h = frame.height;
  final nc = frame.numChannels;
  final stride = frame.data!.rowStride;
  final data = frame.toUint8List();
  final k = Float64List.fromList([for (var i = 0; i < 9; ++i) filter[i] * 1.0]);
  final d = div.toDouble();
  final o = offset.toDouble();
  final mx = (1 * amount).toDouble();
  final invMx = 1 - mx;

  // The byte offsets of each pixel's left, center and right neighbors.
  final cols = Int32List(w * 3);
  for (var x = 0; x < w; ++x) {
    cols[x * 3] = max(x - 1, 0) * nc;
    cols[x * 3 + 1] = x * nc;
    cols[x * 3 + 2] = min(x + 1, w - 1) * nc;
  }

  var above = Uint8List.fromList(Uint8List.sublistView(data, 0, stride));
  var center = Uint8List.fromList(above);
  for (var y = 0; y < h; ++y) {
    // The last row's row below is itself, whose original is center.
    final last = y + 1 == h;
    final belowOffset = last ? 0 : (y + 1) * stride;
    _convolutionRow(above, center, last ? center : data, belowOffset, data,
        y * stride, w, k, d, o, mx, invMx, cols);
    // The next row's above is this row's original, and its center is the row
    // below, which is still unmodified.
    final t = above;
    above = center;
    center = t;
    if (y + 1 < h) {
      center.setRange(0, stride, data, belowOffset);
    }
  }
}

void _convolutionRow(
    Uint8List above,
    Uint8List center,
    Uint8List below,
    int belowOffset,
    Uint8List out,
    int outOffset,
    int w,
    Float64List k,
    double div,
    double offset,
    double mx,
    double invMx,
    Int32List cols) {
  for (var x = 0; x < w; ++x) {
    final l = cols[x * 3];
    final c = cols[x * 3 + 1];
    final r = cols[x * 3 + 2];
    for (var ch = 0; ch < 3; ++ch) {
      var sum = 0.0;
      sum += above[l + ch] * k[0];
      sum += above[c + ch] * k[1];
      sum += above[r + ch] * k[2];
      sum += center[l + ch] * k[3];
      sum += center[c + ch] * k[4];
      sum += center[r + ch] * k[5];
      sum += below[belowOffset + l + ch] * k[6];
      sum += below[belowOffset + c + ch] * k[7];
      sum += below[belowOffset + r + ch] * k[8];
      var v = sum / div + offset;
      v = v < 0
          ? 0.0
          : v > 255
              ? 255.0
              : v;
      final i = outOffset + c + ch;
      final m = center[c + ch] * invMx + v * mx;
      out[i] = m < 0
          ? 0
          : m > 255
              ? 255
              : m.toInt();
    }
  }
}
