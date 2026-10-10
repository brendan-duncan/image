import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (amount == 0.0) {
    return src;
  }
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    if (mask == null &&
        frame.format == Format.uint8 &&
        frame.numChannels >= 3) {
      _sobelUint8(frame, amount);
      continue;
    }
    final orig = Image.from(frame, noAnimation: true);
    final width = frame.width;
    final height = frame.height;
    for (final p in frame) {
      final ny = (p.y - 1).clamp(0, height - 1);
      final py = (p.y + 1).clamp(0, height - 1);
      final nx = (p.x - 1).clamp(0, width - 1);
      final px = (p.x + 1).clamp(0, width - 1);

      final bottomLeft = orig.getPixel(nx, py).luminanceNormalized;
      final topLeft = orig.getPixel(nx, ny).luminanceNormalized;
      final bottomRight = orig.getPixel(px, py).luminanceNormalized;
      final topRight = orig.getPixel(px, ny).luminanceNormalized;
      final left = orig.getPixel(nx, p.y).luminanceNormalized;
      final right = orig.getPixel(px, p.y).luminanceNormalized;
      final bottom = orig.getPixel(p.x, py).luminanceNormalized;
      final top = orig.getPixel(p.x, ny).luminanceNormalized;

      final h =
          -topLeft - 2 * top - topRight + bottomLeft + 2 * bottom + bottomRight;

      final v =
          -bottomLeft - 2 * left - topLeft + bottomRight + 2 * right + topRight;

      final mag = sqrt(h * h + v * v) * p.maxChannelValue;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;
      final invMx = 1 - mx;

      p
        ..r = mag * mx + p.r * invMx
        ..g = mag * mx + p.g * invMx
        ..b = mag * mx + p.b * invMx;
    }
  }

  return src;
}

// A fast path for RGB(A) uint8 images, computing the same values as the
// general path. Rows are filtered in place from the luminance of the
// original rows above, at and below, computed before they're overwritten.
void _sobelUint8(Image frame, num amount) {
  final w = frame.width;
  final h = frame.height;
  final nc = frame.numChannels;
  final stride = frame.data!.rowStride;
  final data = frame.toUint8List();
  final mx = (1 * amount).toDouble();
  final invMx = 1 - mx;

  var above = Float64List(w);
  var center = Float64List(w);
  var below = Float64List(w);
  _luminanceRow(data, 0, nc, center);
  above.setRange(0, w, center);
  for (var y = 0; y < h; ++y) {
    if (y + 1 < h) {
      _luminanceRow(data, (y + 1) * stride, nc, below);
    } else {
      below.setRange(0, w, center);
    }
    _sobelRow(above, center, below, data, y * stride, w, nc, mx, invMx);
    final t = above;
    above = center;
    center = below;
    below = t;
  }
}

// The normalized luminance of each pixel of the row at offset o, as
// PixelUint8.luminanceNormalized computes it.
void _luminanceRow(Uint8List data, int o, int nc, Float64List out) {
  for (var x = 0, i = o; x < out.length; ++x, i += nc) {
    out[x] = 0.299 * (data[i] / 255) +
        0.587 * (data[i + 1] / 255) +
        0.114 * (data[i + 2] / 255);
  }
}

void _sobelRow(Float64List above, Float64List center, Float64List below,
    Uint8List out, int o, int w, int nc, double mx, double invMx) {
  for (var x = 0; x < w; ++x) {
    final nx = x > 0 ? x - 1 : 0;
    final px = x + 1 < w ? x + 1 : w - 1;
    final bottomLeft = below[nx];
    final topLeft = above[nx];
    final bottomRight = below[px];
    final topRight = above[px];
    final left = center[nx];
    final right = center[px];
    final bottom = below[x];
    final top = above[x];

    final h =
        -topLeft - 2 * top - topRight + bottomLeft + 2 * bottom + bottomRight;
    final v =
        -bottomLeft - 2 * left - topLeft + bottomRight + 2 * right + topRight;
    final mag = sqrt(h * h + v * v) * 255;

    final i = o + x * nc;
    for (var c = 0; c < 3; ++c) {
      final m = mag * mx + out[i + c] * invMx;
      out[i + c] = m < 0
          ? 0
          : m > 255
              ? 255
              : m.toInt();
    }
  }
}
