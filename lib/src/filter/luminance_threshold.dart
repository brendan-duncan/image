import 'dart:math';

import '../image/image.dart';
import '../util/math_util.dart';

///
Image luminanceThreshold(Image src, { num threshold = 0.5,
    bool outputColor = false, num amount = 1 }) {
  for (final frame in src.frames) {
    for (final p in frame) {
      final y = 0.3 * p.rNormalized +
          0.59 * p.gNormalized +
          0.11 * p.bNormalized;
      if (outputColor) {
        final l = max(0, y - threshold);
        final sl = sign(l);
        p..r = mix(p.r, p.r * sl, amount)
        ..g = mix(p.g, p.g * sl, amount)
        ..b *= mix(p.b, p.b * sl, amount);
      } else {
        final y2 = y < threshold ? 0 : p.maxChannelValue;
        p..r = mix(p.r, y2, amount)
        ..g = mix(p.g, y2, amount)
        ..b = mix(p.b, y2, amount);
      }
    }
  }
  return src;
}
