import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/image_exception.dart';
import 'bake_orientation.dart';

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
  final dx = src.width / w;
  for (var x = 0; x < w; ++x) {
    scaleX[x] = (x * dx).toInt();
  }
  final scaleY = Int32List(h);
  final dy = src.height / h;
  for (var y = 0; y < h; ++y) {
    scaleY[y] = (y * dy).toInt();
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
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

    switch (interpolation) {
      case Interpolation.lanczos:
        // implementation based on https://github.com/Megakuul/image_scaler/blob/main/lib/lanczos.dart
        final srcPixel = frame.getPixelSafe(0, 0);
        double _kernel(double x, int a) {
          if (x == 0) return 1;
          if (x.abs() >= a) return 0;
          return a * sin(pi * x) * sin(pi * x / a) / (pi * pi * x * x);
        }

        final lanczosXScale = frame.width > w ? dx : 1;
        final lanczosYScale = frame.height > h ? dy : 1;

        const areaSize = 1;
        const maxAreaDiameter = (areaSize * 2) + 1;

        double iX;
        double iY;

        double tWeight;
        final rgbStack = Uint32List(4);

        double _dx;
        double _dy;
        double d;
        double curWeight;

        ({int x, int y}) iAreaTLAnchor, iAreaBRAnchor;

        for (var x = 0; x < w; ++x) {
          iX = x * dx;
          for (var y = 0; y < h; ++y) {
            iY = y * dy;

            // Top Left Area Anchor
            iAreaTLAnchor = (
              x: (iX - areaSize < 0 ? 0 : iX - areaSize).toInt(),
              y: (iY - areaSize < 0 ? 0 : iY - areaSize).toInt()
            );
            // Bottom Right Area Anchor
            iAreaBRAnchor = (
              x: (iAreaTLAnchor.x + maxAreaDiameter).clamp(0, frame.width),
              y: (iAreaTLAnchor.y + maxAreaDiameter).clamp(0, frame.height),
            );

            tWeight = 0;
            rgbStack.fillRange(0, 3, 0);

            for (var iXArea = iAreaTLAnchor.x;
                iXArea < iAreaBRAnchor.x;
                iXArea++) {
              for (var iYArea = iAreaTLAnchor.y;
                  iYArea < iAreaBRAnchor.y;
                  iYArea++) {
                _dx = (iXArea - iX).abs() / lanczosXScale;
                _dy = (iYArea - iY).abs() / lanczosYScale;
                d = sqrt(_dx * _dx + _dy * _dy);
                curWeight = _kernel(d, areaSize);

                frame.getPixel(iXArea, iYArea, srcPixel);
                rgbStack[0] += (srcPixel.r * curWeight).round();
                rgbStack[1] += (srcPixel.g * curWeight).round();
                rgbStack[2] += (srcPixel.b * curWeight).round();
                rgbStack[3] += (srcPixel.a * curWeight).round();

                tWeight += curWeight;
              }
            }

            dst.setPixelRgba(
              x1 + x,
              y1 + y,
              (rgbStack[0] / tWeight).clamp(0, 255).round(),
              (rgbStack[1] / tWeight).clamp(0, 255).round(),
              (rgbStack[2] / tWeight).clamp(0, 255).round(),
              (rgbStack[3] / tWeight).clamp(0, 255).round(),
            );
          }
        }
      case Interpolation.average:
        final srcPixel = frame.getPixelSafe(0, 0);
        for (var y = 0; y < h; ++y) {
          final ay1 = (y * dy).toInt();
          var ay2 = ((y + 1) * dy).toInt();
          if (ay2 == ay1) {
            ay2++;
          }

          for (var x = 0; x < w; ++x) {
            final ax1 = (x * dx).toInt();
            var ax2 = ((x + 1) * dx).toInt();
            if (ax2 == ax1) {
              ax2++;
            }

            num r = 0;
            num g = 0;
            num b = 0;
            num a = 0;
            var np = 0;
            for (var sy = ay1; sy < ay2; ++sy) {
              for (var sx = ax1; sx < ax2; ++sx, ++np) {
                frame.getPixel(sx, sy, srcPixel);
                r += srcPixel.r;
                g += srcPixel.g;
                b += srcPixel.b;
                a += srcPixel.a;
              }
            }
            dst.setPixelRgba(x1 + x, y1 + y, r / np, g / np, b / np, a / np);
          }
        }
      case Interpolation.nearest:
        if (frame.hasPalette) {
          for (var y = 0; y < h; ++y) {
            final y2 = (y * dy).toInt();
            for (var x = 0; x < w; ++x) {
              dst.setPixelIndex(
                  x1 + x, y1 + y, frame.getPixelIndex(scaleX[x], y2));
            }
          }
        } else {
          final srcPixel = frame.getPixelSafe(0, 0);
          for (var y = 0; y < h; ++y) {
            for (var x = 0; x < w; ++x) {
              frame.getPixel(scaleX[x], scaleY[y], srcPixel);
              dst.setPixelRgba(x1 + x, y1 + y, srcPixel.r, srcPixel.g,
                  srcPixel.b, srcPixel.a);
              // Not calling setPixel which triggers runtime type checking
              // mainly for hasPalette routine. Palette images are treated in
              // the above if-else block.
              //dst.setPixel(x1 + x, y1 + y, frame.getPixel(scaleX[x], y2));
            }
          }
        }
      case Interpolation.linear:
        // 4 predefined pixel object for 4 vertices
        final icc = frame.getPixelSafe(0, 0);
        final icn = frame.getPixelSafe(0, 0);
        final inc = frame.getPixelSafe(0, 0);
        final inn = frame.getPixelSafe(0, 0);

        num linear(num icc, num inc, num icn, num inn, num kx, num ky) =>
            icc +
            kx * (inc - icc + ky * (icc + inn - icn - inc)) +
            ky * (icn - icc);

        // Copy the pixels from this image to the new image.
        for (var y = 0; y < h; ++y) {
          final sy2 = y * dy;
          for (var x = 0; x < w; ++x) {
            final sx2 = x * dx;
            final fx = sx2.clamp(0, frame.width - 1);
            final fy = sy2.clamp(0, frame.height - 1);
            final ix = fx.toInt();
            final iy = fy.toInt();
            final kx = fx - ix;
            final ky = fy - iy;
            final nx = (ix + 1).clamp(0, frame.width - 1);
            final ny = (iy + 1).clamp(0, frame.height - 1);

            frame
              ..getPixel(ix, iy, icc)
              ..getPixel(ix, ny, icn)
              ..getPixel(nx, iy, inc)
              ..getPixel(nx, ny, inn);

            dst.setPixelRgba(
                x1 + x,
                y1 + y,
                linear(icc.r, inc.r, icn.r, inn.r, kx, ky),
                linear(icc.g, inc.g, icn.g, inn.g, kx, ky),
                linear(icc.b, inc.b, icn.b, inn.b, kx, ky),
                linear(icc.a, inc.a, icn.a, inn.a, kx, ky));
          }
        }
      case Interpolation.cubic:
        // Copy the pixels from this image to the new image.
        for (var y = 0; y < h; ++y) {
          final sy2 = y * dy;
          for (var x = 0; x < w; ++x) {
            final sx2 = x * dx;
            dst.setPixel(
                x1 + x,
                y1 + y,
                frame.getPixelInterpolate(sx2, sy2,
                    interpolation: interpolation));
          }
        }
    }
  }

  return firstFrame!;
}
