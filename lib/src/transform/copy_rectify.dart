import '../image.dart';
import '../util/point.dart';

/**
 * Returns a copy of the [src] image, where the given rectangle
 * has been mapped to the full image.
 */
Image copyRectify(Image src,
    {Point topLeft,
    Point topRight,
    Point bottomLeft,
    Point bottomRight,
    Image toImage = null}) {
  Image dst = toImage == null ? Image.from(src) : toImage;
  for (int y = 0; y < dst.height; ++y) {
    double v = y / (dst.height - 1);
    for (int x = 0; x < dst.width; ++x) {
      double u = x / (dst.width - 1);
      // bilinear interpolation
      Point srcPixelCoord = topLeft * (1 - u) * (1 - v) +
          topRight * (u) * (1 - v) +
          bottomLeft * (1 - u) * (v) +
          bottomRight * (u) * (v);
      var srcPixel = src.getPixel(srcPixelCoord.xi, srcPixelCoord.yi);
      dst.setPixel(x, y, srcPixel);
    }
  }
  return dst;
}
