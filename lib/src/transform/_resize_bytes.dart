import 'dart:typed_data';

import '../color/format.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '_pixel_bytes.dart';

/// Whether [resizeBytes] supports resizing [frame] with [interpolation].
bool canResizeBytes(Image frame, Interpolation interpolation) =>
    interpolation == Interpolation.nearest
        ? bytesPerPixel(frame) > 0
        : frame.format == Format.uint8 && !frame.hasPalette;

/// The width of [frame] once [orientation] (an EXIF orientation) is applied.
int orientedWidth(Image frame, int orientation) =>
    orientation >= 5 && orientation <= 8 ? frame.height : frame.width;

/// The height of [frame] once [orientation] (an EXIF orientation) is applied.
int orientedHeight(Image frame, int orientation) =>
    orientation >= 5 && orientation <= 8 ? frame.width : frame.height;

/// Fast paths for copyResize that work on the image bytes, giving the same
/// result as its per-pixel code. [frame], with its EXIF [orientation] applied
/// as bakeOrientation does, is resized to the w x h region at (x1, y1) of
/// [dst], with source pixel (x * dx, y * dy) for destination pixel (x, y).
/// Returns false if the image format isn't supported.
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
    Int32List scaleY,
    {int orientation = 1}) {
  if (!canResizeBytes(frame, interpolation)) {
    return false;
  }
  final src = _OrientedSource(frame, orientation);
  final out = dst.toUint8List();
  final dstStride = dst.data!.rowStride;

  if (interpolation == Interpolation.nearest) {
    if (bytesPerPixel(dst) != src.k) {
      return false;
    }
    _resizeNearest(src, out, dstStride, x1, y1, w, h, scaleX, scaleY);
    return true;
  }

  // The interpolating paths compute each channel independently, so for uint8
  // images they can work on the bytes.
  if (dst.format != Format.uint8 ||
      dst.data!.numChannels != frame.data!.numChannels) {
    return false;
  }
  switch (interpolation) {
    case Interpolation.linear:
      _resizeLinear(src, out, dstStride, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.average:
      _resizeAverage(src, out, dstStride, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.cubic:
      _resizeCubic(src, out, dstStride, x1, y1, w, h, dx, dy);
      return true;
    case Interpolation.nearest:
      return false;
  }
}

// The bytes of a frame seen with an EXIF orientation applied: the pixel at
// (x, y) of the oriented image starts at byte base + x * colStep + y * rowStep.
class _OrientedSource {
  final Uint8List bytes;
  final int k;
  final int width;
  final int height;
  late final int base;
  late final int colStep;
  late final int rowStep;

  _OrientedSource(Image frame, int orientation)
      : bytes = frame.toUint8List(),
        k = bytesPerPixel(frame),
        width = orientedWidth(frame, orientation),
        height = orientedHeight(frame, orientation) {
    final stride = frame.data!.rowStride;
    final lastCol = (frame.width - 1) * k;
    final lastRow = (frame.height - 1) * stride;
    switch (orientation) {
      case 2: // flip horizontal
        base = lastCol;
        colStep = -k;
        rowStep = stride;
        break;
      case 3: // rotate 180
        base = lastRow + lastCol;
        colStep = -k;
        rowStep = -stride;
        break;
      case 4: // flip vertical
        base = lastRow;
        colStep = k;
        rowStep = -stride;
        break;
      case 5: // transpose
        base = 0;
        colStep = stride;
        rowStep = k;
        break;
      case 6: // rotate 90
        base = lastRow;
        colStep = -stride;
        rowStep = k;
        break;
      case 7: // transverse
        base = lastRow + lastCol;
        colStep = -stride;
        rowStep = -k;
        break;
      case 8: // rotate 270
        base = lastCol;
        colStep = stride;
        rowStep = -k;
        break;
      default:
        base = 0;
        colStep = k;
        rowStep = stride;
        break;
    }
  }

  int row(int y) => base + y * rowStep;
}

void _resizeNearest(_OrientedSource src, Uint8List out, int dstStride, int x1,
    int y1, int w, int h, Int32List scaleX, Int32List scaleY) {
  final k = src.k;
  final s = src.bytes;
  final srcX = Int32List(w);
  for (var x = 0; x < w; ++x) {
    srcX[x] = scaleX[x] * src.colStep;
  }
  for (var y = 0; y < h; ++y) {
    final srcRow = src.row(scaleY[y]);
    var di = (y1 + y) * dstStride + x1 * k;
    for (var x = 0; x < w; ++x) {
      final si = srcRow + srcX[x];
      for (var c = 0; c < k; ++c) {
        out[di++] = s[si + c];
      }
    }
  }
}

void _resizeLinear(_OrientedSource src, Uint8List out, int dstStride, int x1,
    int y1, int w, int h, double dx, double dy) {
  final nc = src.k;
  final maxX = src.width - 1;
  final maxY = src.height - 1;
  final ixs = Int32List(w);
  final nxs = Int32List(w);
  final kxs = Float64List(w);
  for (var x = 0; x < w; ++x) {
    final fx = x * dx;
    final ix = fx.toInt();
    kxs[x] = fx - ix;
    ixs[x] = ix * src.colStep;
    nxs[x] = (ix + 1).clamp(0, maxX) * src.colStep;
  }
  for (var y = 0; y < h; ++y) {
    final fy = y * dy;
    final iy = fy.toInt();
    final ky = fy - iy;
    final ny = (iy + 1).clamp(0, maxY);
    _linearRow(src.bytes, src.row(iy), src.row(ny), out,
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

void _resizeAverage(_OrientedSource src, Uint8List out, int dstStride, int x1,
    int y1, int w, int h, double dx, double dy) {
  final nc = src.k;
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
      for (var c = 0; c < nc; ++c) {
        sums[c] = 0;
      }
      for (var sy = ay1; sy < ay2; ++sy) {
        _sumRow(src.bytes, src.row(sy) + ax1 * src.colStep, ax2 - ax1,
            src.colStep, nc, sums);
      }
      // Integer sums are exact in doubles, so this matches summing doubles.
      final inv = 1.0 / ((ay2 - ay1) * (ax2 - ax1));
      for (var c = 0; c < nc; ++c) {
        out[di++] = (sums[c] * inv).toInt();
      }
    }
  }
}

void _sumRow(Uint8List src, int si, int n, int step, int nc, Int32List sums) {
  for (var i = 0; i < n; ++i, si += step) {
    for (var c = 0; c < nc; ++c) {
      sums[c] += src[si + c];
    }
  }
}

// Matches Image.getPixelCubic: a tap whose row or column is outside the
// image uses the center pixel.
void _resizeCubic(_OrientedSource src, Uint8List out, int dstStride, int x1,
    int y1, int w, int h, double dx, double dy) {
  final nc = src.k;
  final s = src.bytes;
  // For each destination column, the source column offsets of the four taps,
  // whether they're inside the image, and the fraction.
  final cols = Int32List(w * 4);
  final colInside = Uint8List(w * 4);
  final fxs = Float64List(w);
  for (var x = 0; x < w; ++x) {
    final fx = x * dx;
    final ix = fx.toInt();
    fxs[x] = fx - ix;
    for (var t = 0; t < 4; ++t) {
      final cx = ix + t - 1;
      cols[x * 4 + t] = cx * src.colStep;
      colInside[x * 4 + t] = cx < 0 || cx >= src.width ? 0 : 1;
    }
  }
  final rows = Int32List(4);
  final rowInside = Uint8List(4);
  final taps = Int32List(16);
  final p = Float64List(4);
  for (var y = 0; y < h; ++y) {
    final fy = y * dy;
    final iy = fy.toInt();
    final ky = fy - iy;
    for (var t = 0; t < 4; ++t) {
      final cy = iy + t - 1;
      rows[t] = src.row(cy);
      rowInside[t] = cy < 0 || cy >= src.height ? 0 : 1;
    }
    var di = (y1 + y) * dstStride + x1 * nc;
    for (var x = 0; x < w; ++x) {
      final center = rows[1] + cols[x * 4 + 1];
      for (var r = 0; r < 4; ++r) {
        for (var t = 0; t < 4; ++t) {
          taps[r * 4 + t] = rowInside[r] == 0 || colInside[x * 4 + t] == 0
              ? center
              : rows[r] + cols[x * 4 + t];
        }
      }
      final kx = fxs[x];
      for (var c = 0; c < nc; ++c) {
        for (var r = 0; r < 4; ++r) {
          final o = r * 4;
          p[r] = _cubic(
              kx,
              s[taps[o] + c].toDouble(),
              s[taps[o + 1] + c].toDouble(),
              s[taps[o + 2] + c].toDouble(),
              s[taps[o + 3] + c].toDouble());
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
