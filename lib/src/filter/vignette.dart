import 'dart:math';

import '../image.dart';
import '../internal/clamp.dart';

double _smoothStep(double edge0, double edge1, double x) {
  x = ((x - edge0) / (edge1 - edge0));
  if (x < 0.0) {
    x = 0.0;
  }
  if (x > 1.0) {
    x = 1.0;
  }
  return x * x * (3.0 - 2.0 * x);
}

Image vignette(Image src,
    {double start = 0.3, double end = 0.75, double amount = 0.8}) {
  final int h = src.height - 1;
  final int w = src.width - 1;
  double invAmt = 1.0 - amount;
  var p = src.getBytes();
  for (int y = 0, i = 0; y <= h; ++y) {
    double dy = 0.5 - (y / h);
    for (int x = 0; x <= w; ++x, i += 4) {
      double dx = 0.5 - (x / w);

      double d = sqrt(dx * dx + dy * dy);
      d = _smoothStep(end, start, d);

      p[i] = clamp255((amount * p[i] * d + invAmt * p[i]).toInt());
      p[i + 1] = clamp255((amount * p[i + 1] * d + invAmt * p[i + 1]).toInt());
      p[i + 2] = clamp255((amount * p[i + 2] * d + invAmt * p[i + 2]).toInt());
    }
  }

  return src;
}
