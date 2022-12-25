import '../image/image.dart';
import '../util/color_util.dart';
import '../util/math_util.dart';

/// Convert the image to grayscale.
Image grayscale(Image src, { num amount = 1}) {
  for (final frame in src.frames) {
    if (frame.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        final l = getLuminanceRgb(p.getRed(i), p.getGreen(i), p.getBlue(i));
        if (amount != 1) {
         final r = mix(p.getRed(i), l, amount);
         final g = mix(p.getGreen(i), l, amount);
         final b = mix(p.getBlue(i), l, amount);
         p..setRed(i, r)
         ..setGreen(i, g)
         ..setBlue(i, b);
        } else {
          p..setRed(i, l)
          ..setGreen(i, l)
          ..setBlue(i, l);
        }
      }
    } else {
      for (final p in frame) {
        final l = getLuminanceRgb(p.r, p.g, p.b);
        if (amount != 1) {
          p..r = mix(p.r, l, amount)
          ..g = mix(p.g, l, amount)
          ..b = mix(p.b, l, amount);
        } else {
          p..r = l
          ..g = l
          ..b = l;
        }
      }
    }
  }

  return src;
}
