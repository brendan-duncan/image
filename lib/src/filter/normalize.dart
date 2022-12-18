import '../image/image.dart';
import '../util/min_max.dart';

/// Linearly normalize the colors of the image. All color values will be mapped
/// to the range [minValue], [maxValue] inclusive.
Image normalize(Image src, num minValue, num maxValue) {
  final A = minValue < maxValue ? minValue : maxValue;
  final B = minValue < maxValue ? maxValue : minValue;

  final mM = minMax(src);
  final m = mM[0];
  final M = mM[1];

  if (m == M) {
    return src;
    //return fill(src, minValue);
  }

  final fm = m.toDouble();
  final fM = M.toDouble();

  if (m != A || M != B) {
    for (var p in src) {
      p.r = (p.r - fm) / (fM - fm) * (B - A) + A;
      p.g = (p.g - fm) / (fM - fm) * (B - A) + A;
      p.b = (p.b - fm) / (fM - fm) * (B - A) + A;
      p.a = (p.a - fm) / (fM - fm) * (B - A) + A;
    }
  }

  return src;
}
