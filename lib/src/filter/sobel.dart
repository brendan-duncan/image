import 'dart:math';

import '../image/image.dart';
import 'grayscale.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src, { num amount = 1.0 }) {
  if (amount == 0.0) {
    return src;
  }

  final num invAmount = 1.0 - amount;
  final orig = grayscale(Image.from(src));

  for (final frame in src.frames) {
    for (final p in frame) {
      final bl = orig.getPixelSafe(p.x - 1, p.y + 1);
      final b = orig.getPixelSafe(p.x, p.y - 1);
      final br = orig.getPixelSafe(p.x + 1, p.y + 1);
      final l = orig.getPixelSafe(p.x - 1, p.y);
      final r = orig.getPixelSafe(p.x + 1, p.y);
      final tl = orig.getPixelSafe(p.x - 1, p.y - 1);
      final t = orig.getPixelSafe(p.x, p.y - 1);
      final tr = orig.getPixelSafe(p.x + 1, p.y - 1);

      final blInt = bl.r / bl.maxChannelValue;
      final bInt = b.r / b.maxChannelValue;
      final brInt = br.r / br.maxChannelValue;
      final lInt = l.r / l.maxChannelValue;
      final rInt = r.r / r.maxChannelValue;
      final tlInt = tl.r / tl.maxChannelValue;
      final tInt = t.r / t.maxChannelValue;
      final trInt = tr.r / tr.maxChannelValue;

      final h = -tlInt - 2.0 * tInt - trInt + blInt + 2.0 * bInt + brInt;
      final v = -blInt - 2.0 * lInt - tlInt + brInt + 2.0 * rInt + trInt;

      final mag = sqrt(h * h + v * v) * p.maxChannelValue;

      p..r = mag * amount + p.r * invAmount
      ..g = mag * amount + p.g * invAmount
      ..b = mag * amount + p.b * invAmount;
    }
  }

  return src;
}
