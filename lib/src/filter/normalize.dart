import 'dart:typed_data';

import '../image.dart';
import '../draw/fill.dart';
import '../util/min_max.dart';

/// Linearly normalize the colors of the image.  All color values will be mapped
/// to the range [minValue], [maxValue] inclusive.
Image normalize(Image src, int minValue, int maxValue) {
  int A = minValue < maxValue ? minValue : maxValue;
  int B = minValue < maxValue ? maxValue : minValue;

  var mM = minMax(src);
  int m = mM[0];
  int M = mM[1];

  num fm = m.toDouble();
  num fM = M.toDouble();

  if (m == M) {
    return fill(src, minValue);
  }

  if (m != A || M != B) {
    var p = src.getBytes();
    for (int i = 0, len = p.length; i < len; i += 4) {
      p[i] = ((p[i] - fm) / (fM - fm) * (B - A) + A).toInt();
      p[i + 1] = ((p[i + 1] - fm) / (fM - fm) * (B - A) + A).toInt();
      p[i + 2] = ((p[i + 2] - fm) / (fM - fm) * (B - A) + A).toInt();
      p[i + 3] = ((p[i + 3] - fm) / (fM - fm) * (B - A) + A).toInt();
    }
  }

  return src;
}
