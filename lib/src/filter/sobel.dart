import 'dart:math';

import '../image.dart';
import '../internal/clamp.dart';
import 'grayscale.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src, {double amount = 1.0}) {
  double invAmount = 1.0 - amount;
  Image orig = grayscale(new Image.from(src));
  final List<int> origRGBA = orig.getBytes();
  int rowSize = src.width * 4;
  List<int> rgba = src.getBytes();
  final rgbaLen = rgba.length;
  for (int y = 0, pi = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x, pi += 4) {
      int bl = pi + rowSize - 4;
      int b = pi + rowSize;
      int br = pi + rowSize + 4;
      int l = pi - 4;
      int r = pi + 4;
      int tl = pi - rowSize - 4;
      int t = pi - rowSize;
      int tr = pi - rowSize + 4;

      double tlInt = tl < 0 ? 0.0 : origRGBA[tl] / 255.0;
      double tInt = t < 0 ? 0.0 : origRGBA[t] / 255.0;
      double trInt = tr < 0 ? 0.0 : origRGBA[tr] / 255.0;
      double lInt = l < 0 ? 0.0 : origRGBA[l] / 255.0;
      double rInt = r < rgbaLen ? origRGBA[r] / 255.0 : 0.0;
      double blInt = bl < rgbaLen ? origRGBA[bl] / 255.0 : 0.0;
      double bInt = b < rgbaLen ? origRGBA[b] / 255.0 : 0.0;
      double brInt = br < rgbaLen ? origRGBA[br] / 255.0 : 0.0;

      double h = -tlInt - 2.0 * tInt - trInt + blInt + 2.0 * bInt + brInt;
      double v = -blInt - 2.0 * lInt - tlInt + brInt + 2.0 * rInt + trInt;

      int mag = clamp255((sqrt(h * h + v * v) * 255.0).toInt());

      rgba[pi] = clamp255((mag * amount + rgba[pi] * invAmount).toInt());
      rgba[pi + 1] =
          clamp255((mag * amount + rgba[pi + 1] * invAmount).toInt());
      rgba[pi + 2] =
          clamp255((mag * amount + rgba[pi + 2] * invAmount).toInt());
    }
  }

  return src;
}
