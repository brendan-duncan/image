import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/color_util.dart';
import '../util/image_exception.dart';
import 'bake_orientation.dart';
import 'copy_resize.dart';

Image resize(Image src,
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
    return src;
  }

  if ((width * height) > (src.width * src.height)) {
    return copyResize(src,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
        backgroundColor: backgroundColor,
        interpolation: interpolation);
  }

  final scaleX = Int32List(w);
  final dx = src.width / w;
  for (var x = 0; x < w; ++x) {
    scaleX[x] = (x * dx).toInt();
  }

  final origWidth = src.width;
  final origHeight = src.height;

  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = frame;

    final dy = frame.height / h;
    final dx = frame.width / w;

    if (maintainAspect && backgroundColor != null) {
      dst.clear(backgroundColor);
    }
    switch (interpolation) {
      case Interpolation.lanczos:
        // implementation based on https://github.com/Megakuul/image_scaler/blob/main/lib/lanczos.dart

        // Use oklab color space
        final buffer = Float32x4List(frame.height * frame.width);
        final px = frame.getPixelSafe(0, 0);
        for (var x = 0; x < frame.width; x++) {
          for (var y = 0; y < frame.height; y++) {
            frame.getPixel(x, y, px);
            final alpha = px.aNormalized.toDouble();
            final [
              l,
              a,
              b,
            ] = rgbToOklab(px.r, px.g, px.b);
            buffer[frame.width * y + x] =
                Float32x4(l * alpha, a * alpha, b * alpha, alpha);
          }
        }

        // use factor only for down sampling
        final lanczosXScale = frame.width > w ? dx : 1;
        final lanczosYScale = frame.height > h ? dy : 1;

        const areaSize = 3;
        const maxAreaDiameter = (areaSize * 2) + 1;

        double iX;
        double iY;

        Float32x4 tWeight;
        Float32x4 labStack;
        double _dx;
        double _dy;
        double d;
        Float32x4 curWeight;

        ({int x, int y}) iAreaTLAnchor, iAreaBRAnchor;

        dst.data!.width = width;
        dst.data!.height = height;
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

            tWeight = Float32x4.zero();
            labStack = Float32x4.zero();

            for (var iXArea = iAreaTLAnchor.x;
                iXArea < iAreaBRAnchor.x;
                iXArea++) {
              for (var iYArea = iAreaTLAnchor.y;
                  iYArea < iAreaBRAnchor.y;
                  iYArea++) {
                _dx = (iXArea - iX).abs() / lanczosXScale;
                _dy = (iYArea - iY).abs() / lanczosYScale;
                d = sqrt(_dx * _dx + _dy * _dy);
                curWeight = Float32x4.splat(_lanczosKernel(d, areaSize));
                labStack += buffer[frame.width * iYArea + iXArea] * curWeight;
                tWeight += curWeight;
              }
            }

            labStack /= tWeight;
            final alpha = labStack.w;
            labStack /= Float32x4.splat(alpha);
            final [
              r,
              g,
              b,
            ] = oklabToRgb(labStack.x, labStack.y, labStack.z);
            dst.setPixelRgba(
              x1 + x,
              y1 + y,
              r.clamp(0, 255).round(),
              g.clamp(0, 255).round(),
              b.clamp(0, 255).round(),
              (alpha * 255).clamp(0, 255).round(),
            );
          }
        }
        dst.data!.width = origWidth;
        dst.data!.height = origHeight;
      case Interpolation.average:
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
                final s = frame.getPixel(sx, sy);
                r += s.r;
                g += s.g;
                b += s.b;
                a += s.a;
              }
            }
            final c = dst.getColor(r / np, g / np, b / np, a / np);

            dst.data!.width = width;
            dst.data!.height = height;
            dst.setPixel(x1 + x, y1 + y, c);
            dst.data!.width = origWidth;
            dst.data!.height = origHeight;
          }
        }
      case Interpolation.nearest:
        if (frame.hasPalette) {
          for (var y = 0; y < h; ++y) {
            final y2 = (y * dy).toInt();
            for (var x = 0; x < w; ++x) {
              final p = frame.getPixelIndex(scaleX[x], y2);
              dst.data!.width = width;
              dst.data!.height = height;
              dst.setPixelIndex(x1 + x, y1 + y, p);
              dst.data!.width = origWidth;
              dst.data!.height = origHeight;
            }
          }
        } else {
          for (var y = 0; y < h; ++y) {
            final y2 = (y * dy).toInt();
            for (var x = 0; x < w; ++x) {
              final p = frame.getPixel(scaleX[x], y2);
              dst.data!.width = width;
              dst.data!.height = height;
              dst.setPixel(x1 + x, y1 + y, p);
              dst.data!.width = origWidth;
              dst.data!.height = origHeight;
            }
          }
        }
      case Interpolation.cubic:
      case Interpolation.linear:
        // Copy the pixels from this image to the new image.
        for (var y = 0; y < h; ++y) {
          final sy2 = y * dy;
          for (var x = 0; x < w; ++x) {
            final sx2 = x * dx;
            final p = frame.getPixelInterpolate(x1 + sx2, y1 + sy2,
                interpolation: interpolation);
            dst.data!.width = width;
            dst.data!.height = height;
            dst.setPixel(x, y, p);
            dst.data!.width = origWidth;
            dst.data!.height = origHeight;
          }
        }
    }
  }

  return src;
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
double _lanczosKernel(double x, int a) {
  if (x == 0) return 1;
  if (x.abs() >= a) return 0;
  return a * sin(pi * x) * sin(pi * x / a) / (pi * pi * x * x);
}
