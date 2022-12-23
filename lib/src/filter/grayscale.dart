import '../color/color_util.dart';
import '../image/image.dart';

/// Convert the image to grayscale.
Image grayscale(Image src) {
  for (final frame in src.frames) {
    if (frame.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        final l = getLuminanceRgb(p.getRed(i), p.getGreen(i), p.getBlue(i));
        p.setColor(i, l, l, l);
      }
    } else {
      for (final p in frame) {
        final l = getLuminanceRgb(p.r, p.g, p.b);
        p..r = l
        ..g = l
        ..b = l;
      }
    }
  }

  return src;
}
