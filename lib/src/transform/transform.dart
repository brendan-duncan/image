import 'dart:math';

import '../image.dart';

/**
 * Transform image [src] to rectify perspective with oblique quadrilateral
 * by given four corners [topLeft], [topRight], [bottomLeft], [bottomRight].
 */
Image rectify(Image src, Point topLeft, Point topRight, Point bottomLeft,
    Point bottomRight) {
  Image dstImage = Image.from(src);
  for (int y = 0; y < dstImage.height; ++y) {
    double v = y / (dstImage.height - 1);
    for (int x = 0; x < dstImage.width; ++x) {
      double u = x / (dstImage.width - 1);
      // bilinear interpolation
      Point srcPixelCoord = topLeft * (1 - u) * (1 - v) +
          topRight * (u) * (1 - v) +
          bottomLeft * (1 - u) * (v) +
          bottomRight * (u) * (v);
      var srcPixel = src.getPixel(
          srcPixelCoord.x.round(), srcPixelCoord.y.round());
      dstImage.setPixel(x, y, srcPixel);
    }
  }
  return dstImage;
}
