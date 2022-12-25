import '../util/color_util.dart';
import '../image/image.dart';

/// Apply sepia tone to the image.
///
/// [amount] controls the strength of the effect, in the range 0.0 - 1.0.
Image sepia(Image src, { num amount = 1.0 }) {
  if (amount == 0) {
    return src;
  }

  for (final frame in src.frames) {
    for (var p in frame) {
      final r = p.rNormalized;
      final g = p.gNormalized;
      final b = p.bNormalized;
      final y = getLuminanceRgb(r, g, b);
      p..rNormalized = (amount * (y + 0.15)) + ((1.0 - amount) * r)
      ..gNormalized = (amount * (y + 0.07)) + ((1.0 - amount) * g)
      ..bNormalized = (amount * (y - 0.12)) + ((1.0 - amount) * b);
    }
  }

  return src;
}
