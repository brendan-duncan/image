import '../color/color_util.dart';
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
      final r = p.r;
      final g = p.g;
      final b = p.b;
      final y = getLuminanceRgb(r, g, b);
      p..r = (amount * (y + 38)) + ((1.0 - amount) * r)
      ..g = (amount * (y + 18)) + ((1.0 - amount) * g)
      ..b = (amount * (y - 31)) + ((1.0 - amount) * b);
    }
  }

  return src;
}
