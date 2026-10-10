import 'dart:typed_data';

import '../color/format.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '_pixel_bytes.dart';

/// Fast paths for copyResize that work on the image bytes, giving the same
/// result as its per-pixel code. [frame] is resized to the w x h region at
/// (x1, y1) of [dst], with source pixel (x * dx, y * dy) for destination
/// pixel (x, y). Returns false if the image format isn't supported.
bool resizeBytes(
    Image frame,
    Image dst,
    Interpolation interpolation,
    int x1,
    int y1,
    int w,
    int h,
    double dx,
    double dy,
    Int32List scaleX,
    Int32List scaleY) {
  if (interpolation == Interpolation.nearest) {
    final k = bytesPerPixel(frame);
    if (k == 0 || bytesPerPixel(dst) != k) {
      return false;
    }
    _resizeNearest(
        frame.toUint8List(),
        frame.data!.rowStride,
        dst.toUint8List(),
        dst.data!.rowStride,
        k,
        x1,
        y1,
        w,
        h,
        scaleX,
        scaleY);
    return true;
  }

  // The interpolating paths compute each channel independently, so for uint8
  // images they can work on the bytes.
  if (frame.format != Format.uint8 ||
      frame.hasPalette ||
      dst.format != Format.uint8 ||
      dst.data!.numChannels != frame.data!.numChannels) {
    return false;
  }
  final src = frame.toUint8List();
  final srcStride = frame.data!.rowStride;
  final out = dst.toUint8List();
  final dstStride = dst.data!.rowStride;
  final nc = frame.data!.numChannels;
  final sw = frame.width;
  final sh = frame.height;

  switch (interpolation) {
    case Interpolation.linear:
      _resizeLinear(
          src, srcStride, sw, sh, out, dstStride, nc, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.average:
      _resizeAverage(src, srcStride, out, dstStride, nc, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.cubic:
      _resizeCubic(
          src, srcStride, sw, sh, out, dstStride, nc, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.nearest:
      return false;
  }
}

void _resizeNearest(Uint8List src, int srcStride, Uint8List out, int dstStride,
    int k, int x1, int y1, int w, int h, Int32List scaleX, Int32List scaleY) {
  final srcX = Int32List(w);
  for (var x = 0; x < w; ++x) {
    srcX[x] = scaleX[x] * k;
  }
  for (var y = 0; y < h; ++y) {
    final srcRow = scaleY[y] * srcStride;
    var di = (y1 + y) * dstStride + x1 * k;
    for (var x = 0; x < w; ++x) {
      final si = srcRow + srcX[x];
      for (var c = 0; c < k; ++c) {
        out[di++] = src[si + c];
      }
    }
  }
}

void _resizeLinear(Uint8List src, int srcStride, int sw, int sh, Uint8List out,
    int dstStride, int nc, int x1, int y1, int w, int h, double dx, double dy) {
  final maxX = sw - 1;
  final maxY = sh - 1;
  final ixs = Int32List(w);
  final nxs = Int32List(w);
  final kxs = Float64List(w);
  for (var x = 0; x < w; ++x) {
    final fx = x * dx;
    final ix = fx.toInt();
    kxs[x] = fx - ix;
    ixs[x] = ix * nc;
    nxs[x] = (ix + 1).clamp(0, maxX) * nc;
  }
  for (var y = 0; y < h; ++y) {
    final fy = y * dy;
    final iy = fy.toInt();
    final ky = fy - iy;
    final ny = (iy + 1).clamp(0, maxY);
    _linearRow(src, iy * srcStride, ny * srcStride, out,
        (y1 + y) * dstStride + x1 * nc, nc, w, ixs, nxs, kxs, ky);
  }
}

void _linearRow(Uint8List src, int row0, int row1, Uint8List out, int di,
    int nc, int w, Int32List ixs, Int32List nxs, Float64List kxs, double ky) {
  for (var x = 0; x < w; ++x) {
    final i0 = row0 + ixs[x];
    final n0 = row0 + nxs[x];
    final i1 = row1 + ixs[x];
    final n1 = row1 + nxs[x];
    final kx = kxs[x];
    for (var c = 0; c < nc; ++c) {
      final icc = src[i0 + c].toDouble();
      final inc = src[n0 + c].toDouble();
      final icn = src[i1 + c].toDouble();
      final inn = src[n1 + c].toDouble();
      out[di++] = (icc +
              kx * (inc - icc + ky * (icc + inn - icn - inc)) +
              ky * (icn - icc))
          .toInt();
    }
  }
}

void _resizeAverage(Uint8List src, int srcStride, Uint8List out, int dstStride,
    int nc, int x1, int y1, int w, int h, double dx, double dy) {
  final ax1s = Int32List(w);
  final ax2s = Int32List(w);
  for (var x = 0; x < w; ++x) {
    final ax1 = (x * dx).toInt();
    var ax2 = ((x + 1) * dx).toInt();
    if (ax2 == ax1) {
      ax2++;
    }
    ax1s[x] = ax1;
    ax2s[x] = ax2;
  }
  final sums = Int32List(nc);
  for (var y = 0; y < h; ++y) {
    final ay1 = (y * dy).toInt();
    var ay2 = ((y + 1) * dy).toInt();
    if (ay2 == ay1) {
      ay2++;
    }
    var di = (y1 + y) * dstStride + x1 * nc;
    for (var x = 0; x < w; ++x) {
      final ax1 = ax1s[x];
      final ax2 = ax2s[x];
      sums.fillRange(0, nc, 0);
      for (var sy = ay1; sy < ay2; ++sy) {
        _sumRow(src, sy * srcStride + ax1 * nc, (ax2 - ax1) * nc, nc, sums);
      }
      // Integer sums are exact in doubles, so this matches summing doubles.
      final inv = 1.0 / ((ay2 - ay1) * (ax2 - ax1));
      for (var c = 0; c < nc; ++c) {
        out[di++] = (sums[c] * inv).toInt();
      }
    }
  }
}

void _sumRow(Uint8List src, int si, int n, int nc, Int32List sums) {
  for (var i = 0; i < n; i += nc) {
    for (var c = 0; c < nc; ++c) {
      sums[c] += src[si + i + c];
    }
  }
}

// Matches Image.getPixelCubic: a tap whose row or column is outside the
// image uses the center pixel.
void _resizeCubic(Uint8List src, int srcStride, int sw, int sh, Uint8List out,
    int dstStride, int nc, int x1, int y1, int w, int h, double dx, double dy) {
  // For each destination column, the source column offsets of the four taps
  // (-1 where outside the image) and the fraction.
  final cols = Int32List(w * 4);
  final fxs = Float64List(w);
  for (var x = 0; x < w; ++x) {
    final fx = x * dx;
    final ix = fx.toInt();
    fxs[x] = fx - ix;
    for (var t = 0; t < 4; ++t) {
      final cx = ix + t - 1;
      cols[x * 4 + t] = cx < 0 || cx >= sw ? -1 : cx * nc;
    }
  }
  final rows = Int32List(4);
  final taps = Int32List(16);
  final p = Float64List(4);
  for (var y = 0; y < h; ++y) {
    final fy = y * dy;
    final iy = fy.toInt();
    final ky = fy - iy;
    for (var t = 0; t < 4; ++t) {
      final cy = iy + t - 1;
      rows[t] = cy < 0 || cy >= sh ? -1 : cy * srcStride;
    }
    var di = (y1 + y) * dstStride + x1 * nc;
    for (var x = 0; x < w; ++x) {
      final center = rows[1] + cols[x * 4 + 1];
      for (var r = 0; r < 4; ++r) {
        final row = rows[r];
        for (var t = 0; t < 4; ++t) {
          final col = cols[x * 4 + t];
          taps[r * 4 + t] = row < 0 || col < 0 ? center : row + col;
        }
      }
      final kx = fxs[x];
      for (var c = 0; c < nc; ++c) {
        for (var r = 0; r < 4; ++r) {
          final o = r * 4;
          p[r] = _cubic(
              kx,
              src[taps[o] + c].toDouble(),
              src[taps[o + 1] + c].toDouble(),
              src[taps[o + 2] + c].toDouble(),
              src[taps[o + 3] + c].toDouble());
        }
        final v = _cubic(ky, p[0], p[1], p[2], p[3]);
        out[di++] = v < 0
            ? 0
            : v > 255
                ? 255
                : v.toInt();
      }
    }
  }
}

double _cubic(double dx, double ipp, double icp, double inp, double iap) =>
    icp +
    0.5 *
        (dx * (-ipp + inp) +
            dx * dx * (2 * ipp - 5 * icp + 4 * inp - iap) +
            dx * dx * dx * (-ipp + 3 * icp - 3 * inp + iap));
