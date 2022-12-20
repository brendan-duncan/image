import 'dart:math';

import '../image/image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src, int x, int y, int w, int h) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1).toInt();
  y = y.clamp(0, src.height - 1).toInt();
  if (x + w > src.width) {
    w = src.width - x;
  }
  if (y + h > src.height) {
    h = src.height - y;
  }

  final dst = Image(w, h, numChannels: src.numChannels, format: src.format,
      palette: src.palette, exif: src.exif, iccp: src.iccProfile);

  for (var yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (var xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}

/// Returns a circle cropped copy of [src], centered at [centerX] and
/// [centerY] and with the given [radius]. If [radius] is not provided,
/// a radius filling the image will be used. If [centerX] is not provided,
/// the horizontal mid-point of the image will be used. If [centerY] is not
/// provided, the vertical mid-point of the image will be used.
Image copyCropCircle(Image src, {int? radius, int? centerX, int? centerY}) {
  centerX ??= src.width ~/ 2;
  centerY ??= src.height ~/ 2;
  radius ??= min(src.width, src.height) ~/ 2;

  // Make sure center point is within the range of the src image
  centerX = centerX.clamp(0, src.width - 1);
  centerY = centerY.clamp(0, src.height - 1);
  if (radius < 1) {
    radius = min(src.width, src.height) ~/ 2;
  }

  final tlx = centerX - radius; //topLeft.x
  final tly = centerY - radius; //topLeft.y

  final dst = Image(radius * 2, radius * 2,
    iccp: src.iccProfile, format: src.format, numChannels: src.numChannels,
    palette: src.palette);

  final dh = dst.height;
  final dw = radius * 2;
  for (var yi = 0, sy = tly; yi < dh; ++yi, ++sy) {
    for (var xi = 0, sx = tlx; xi < dw; ++xi, ++sx) {
      if ((xi - radius) * (xi - radius) + (yi - radius) * (yi - radius) <=
          radius * radius) {
        dst.setPixel(xi, yi, src.getPixelSafe(sx, sy));
      }
    }
  }

  return dst;
}
