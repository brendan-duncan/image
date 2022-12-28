import 'dart:math';

import '../image/image.dart';

num _smoothStep(num edge0, num edge1, num x) {
  x = (x - edge0) / (edge1 - edge0);
  if (x < 0.0) {
    x = 0.0;
  }
  if (x > 1.0) {
    x = 1.0;
  }
  return x * x * (3.0 - 2.0 * x);
}

Image vignette(Image src, { num start = 0.3, num end = 0.75,
    num amount = 0.8 }) {
  final h = src.height - 1;
  final w = src.width - 1;
  final invAmt = 1.0 - amount;
  for (final frame in src.frames) {
    for (final p in frame) {
      final dy = 0.5 - (p.y / h);
      final dx = 0.5 - (p.x / w);
      num d = sqrt(dx * dx + dy * dy);
      d = _smoothStep(end, start, d);
      final r = p.r;
      final g = p.g;
      final b = p.b;
      p..r = amount * r * d + invAmt * r
      ..g = amount * g * d + invAmt * g
      ..b = amount * b * d + invAmt * b;
    }
  }
  return src;
}
