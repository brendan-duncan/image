import 'dart:typed_data';

import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/image_exception.dart';
import 'bake_orientation.dart';

double _linear(
        double icc, double inc, double icn, double inn, double kx, double ky) =>
    icc + kx * (inc - icc + ky * (icc + inn - icn - inc)) + ky * (icn - icc);

/// Returns a resized copy of the [src] Image.
/// If [height] isn't specified, then it will be determined by the aspect
/// ratio of [src] and [width].
/// If [width] isn't specified, then it will be determined by the aspect ratio
/// of [src] and [height].
Image copyResize(Image src,
    {int? width,
    int? height,
    bool? maintainAspect,
    Color? backgroundColor,
    Interpolation interpolation = Interpolation.nearest}) {
  if (width == null && height == null) {
    throw ImageException('Invalid size');
  }

  // You can't interpolate index pixels
  if (src.hasPalette) {
    interpolation = Interpolation.nearest;
  }

  if (src.exif.imageIfd.hasOrientation && src.exif.imageIfd.orientation != 1) {
    src = bakeOrientation(src);
  }

  var x1 = 0;
  var y1 = 0;
  var x2 = 0;
  var y2 = 0;

  // this block sets [width] and [height] if null or negative.
  if (width != null && height != null && maintainAspect == true) {
    x1 = 0;
    x2 = width;
    final srcAspect = src.height / src.width;
    final h = (width * srcAspect).toInt();
    final dy = (height - h) ~/ 2;
    y1 = dy;
    y2 = y1 + h;
    if (y1 < 0 || y2 > height) {
      y1 = 0;
      y2 = height;
      final srcAspect = src.width / src.height;
      final w = (height * srcAspect).toInt();
      final dx = (width - w) ~/ 2;
      x1 = dx;
      x2 = x1 + w;
    }
  } else {
    maintainAspect = false;
  }

  if (height == null || height <= 0) {
    height = (width! * (src.height / src.width)).round();
  }
  if (width == null || width <= 0) {
    width = (height * (src.width / src.height)).round();
  }

  final w = maintainAspect! ? x2 - x1 : width;
  final h = maintainAspect ? y2 - y1 : height;

  if (!maintainAspect) {
    x1 = 0;
    x2 = width;
    y1 = 0;
    y2 = height;
  }

  if (width == src.width && height == src.height) {
    return src.clone();
  }

  final scaleX = Int32List(w);
  for (var x = 0; x < w; ++x) {
    scaleX[x] = (x * src.width) ~/ w;
  }
  final scaleY = Int32List(h);
  for (var y = 0; y < h; ++y) {
    scaleY[y] = (y * src.height) ~/ h;
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  final noOffset = x1 == 0 && y1 == 0;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = Image.fromResized(frame,
        width: width, height: height, noAnimation: true);
    firstFrame?.addFrame(dst);
    firstFrame ??= dst;

    final dy = frame.height / h;
    final dx = frame.width / w;

    if (maintainAspect && backgroundColor != null) {
      dst.clear(backgroundColor);
    }

    if (interpolation == Interpolation.average) {
      final srcPixel = frame.getPixelSafe(0, 0);
      for (var y = 0; y < h; ++y) {
        final ay1 = (y * dy).toInt();
        var ay2 = ((y + 1) * dy).toInt();
        if (ay2 == ay1) {
          ay2++;
        }
        final dstY = y1 + y;

        for (var x = 0; x < w; ++x) {
          final ax1 = (x * dx).toInt();
          var ax2 = ((x + 1) * dx).toInt();
          if (ax2 == ax1) {
            ax2++;
          }

          var r = 0.0;
          var g = 0.0;
          var b = 0.0;
          var a = 0.0;
          var np = 0;
          for (var sy = ay1; sy < ay2; ++sy) {
            for (var sx = ax1; sx < ax2; ++sx, ++np) {
              frame.getPixel(sx, sy, srcPixel);
              r += srcPixel.r.toDouble();
              g += srcPixel.g.toDouble();
              b += srcPixel.b.toDouble();
              a += srcPixel.a.toDouble();
            }
          }
          final inv = 1.0 / np;
          dst.setPixelRgba(x1 + x, dstY, r * inv, g * inv, b * inv, a * inv);
        }
      }
    } else if (interpolation == Interpolation.nearest) {
      if (frame.hasPalette) {
        for (var y = 0; y < h; ++y) {
          final y2 = scaleY[y];
          final dstY = y1 + y;
          for (var x = 0; x < w; ++x) {
            dst.setPixelIndex(x1 + x, dstY, frame.getPixelIndex(scaleX[x], y2));
          }
        }
      } else if (noOffset) {
        final srcPixel = frame.getPixelSafe(0, 0);
        for (var y = 0; y < h; ++y) {
          final sy = scaleY[y];
          for (var x = 0; x < w; ++x) {
            frame.getPixel(scaleX[x], sy, srcPixel);
            dst.setPixelRgba(
                x, y, srcPixel.r, srcPixel.g, srcPixel.b, srcPixel.a);
          }
        }
      } else {
        final srcPixel = frame.getPixelSafe(0, 0);
        for (var y = 0; y < h; ++y) {
          final sy = scaleY[y];
          final dstY = y1 + y;
          for (var x = 0; x < w; ++x) {
            frame.getPixel(scaleX[x], sy, srcPixel);
            dst.setPixelRgba(
                x1 + x, dstY, srcPixel.r, srcPixel.g, srcPixel.b, srcPixel.a);
          }
        }
      }
    } else if (interpolation == Interpolation.linear) {
      final icc = frame.getPixelSafe(0, 0);
      final icn = frame.getPixelSafe(0, 0);
      final inc = frame.getPixelSafe(0, 0);
      final inn = frame.getPixelSafe(0, 0);
      final maxX = frame.width - 1;
      final maxY = frame.height - 1;

      for (var y = 0; y < h; ++y) {
        final fy = y * dy;
        final iy = fy.toInt();
        final ky = fy - iy;
        final ny = (iy + 1).clamp(0, maxY);
        final dstY = y1 + y;
        for (var x = 0; x < w; ++x) {
          final fx = x * dx;
          final ix = fx.toInt();
          final kx = fx - ix;
          final nx = (ix + 1).clamp(0, maxX);

          frame
            ..getPixel(ix, iy, icc)
            ..getPixel(ix, ny, icn)
            ..getPixel(nx, iy, inc)
            ..getPixel(nx, ny, inn);

          dst.setPixelRgba(
              x1 + x,
              dstY,
              _linear(icc.r.toDouble(), inc.r.toDouble(), icn.r.toDouble(),
                  inn.r.toDouble(), kx, ky),
              _linear(icc.g.toDouble(), inc.g.toDouble(), icn.g.toDouble(),
                  inn.g.toDouble(), kx, ky),
              _linear(icc.b.toDouble(), inc.b.toDouble(), icn.b.toDouble(),
                  inn.b.toDouble(), kx, ky),
              _linear(icc.a.toDouble(), inc.a.toDouble(), icn.a.toDouble(),
                  inn.a.toDouble(), kx, ky));
        }
      }
    } else {
      for (var y = 0; y < h; ++y) {
        final sy2 = y * dy;
        final dstY = y1 + y;
        for (var x = 0; x < w; ++x) {
          final sx2 = x * dx;
          dst.setPixel(
              x1 + x,
              dstY,
              frame.getPixelInterpolate(sx2, sy2,
                  interpolation: interpolation));
        }
      }
    }
  }

  return firstFrame!;
}
