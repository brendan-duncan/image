import '../color/color.dart';
import '../image/image.dart';

/// Draw a single pixel into the image, applying alpha and opacity blending.
/// If [filter] is provided, the color c will be scaled by the [filter]
/// color. If [alpha] is provided, it will be used in place of the
/// color alpha, as a normalized color value \[0, 1\].
Image drawPixel(Image image, int x, int y, Color c, { Color? filter,
    num? alpha }) {
  final r = filter != null ? c.r * filter.r : c.r;
  final g = filter != null ? c.g * filter.g : c.g;
  final b = filter != null ? c.b * filter.b : c.b;
  final a = alpha != null ? alpha : c.length < 4 ? 1.0 : c.aNormalized;

  if (a == 0) {
    return image;
  }

  if (image.isBoundsSafe(x, y)) {
    final dst = image.getPixel(x, y);
    if (a == 1.0 || image.hasPalette) {
      dst.setColor(r, g, b);
      return image;
    }

    final invA = 1.0 - a;
    dst..r = (r * a) + (dst.r * invA)
      ..g = (g * a) + (dst.g * invA)
      ..b = (b * a) + (dst.b * invA)
      ..a = dst.maxChannelValue;
  }

  return image;
}
