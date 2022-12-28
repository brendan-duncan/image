import '../image/image.dart';
import '../util/min_max.dart';

/// Linearly normalize the colors of the image. All color values will be mapped
/// to the range [minValue], [maxValue] inclusive.
Image normalize(Image src, num minValue, num maxValue) {
  final a = minValue < maxValue ? minValue : maxValue;
  final b = minValue < maxValue ? maxValue : minValue;

  final mM = minMax(src);
  final min = mM[0];
  final max = mM[1];

  if (min == max) {
    return src;
  }

  final fm = min.toDouble();
  final fM = max.toDouble();

  if (min != a || max != b) {
    for (var frame in src.frames) {
      for (final p in frame) {
        p..r = (p.r - fm) / (fM - fm) * (b - a) + a
        ..g = (p.g - fm) / (fM - fm) * (b - a) + a
        ..b = (p.b - fm) / (fM - fm) * (b - a) + a
        ..a = (p.a - fm) / (fM - fm) * (b - a) + a;
      }
    }
  }

  return src;
}
