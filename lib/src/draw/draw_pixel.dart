import '../color/color.dart';
import '../image/image.dart';

/// Draw a single pixel into the image, applying alpha and opacity blending.
Image drawPixel(Image image, int x, int y, Color c, [double? overrideAlpha]) {
  final a = overrideAlpha != null ? overrideAlpha :
      c.length < 4 ? 1.0 : c.a / c.maxChannelValue;

  if (a == 0) {
    return image;
  }

  if (image.isBoundsSafe(x, y)) {
    final dst = image.getPixel(x, y);
    if (a == 1.0 || image.hasPalette) {
      dst.set(c);
      return image;
    }

    final invA = 1.0 - a;
    dst..r = (c.r * a) + (dst.r * invA)
      ..g = (c.g * a) + (dst.g * invA)
      ..b = (c.b * a) + (dst.b * invA)
      ..a = dst.maxChannelValue;
  }

  return image;
}
