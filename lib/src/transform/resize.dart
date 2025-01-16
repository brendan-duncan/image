import 'dart:typed_data';

import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
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
    return copyResize(src, width: width, height: height,
        maintainAspect: maintainAspect, backgroundColor: backgroundColor,
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

    if (interpolation == Interpolation.average) {
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
    } else if (interpolation == Interpolation.nearest) {
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
    } else {
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

    dst.data!.width = width;
    dst.data!.height = height;
  }

  return src;
}
