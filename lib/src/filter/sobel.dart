import 'dart:math';

import '../image.dart';
import '../internal/clamp.dart';
import 'grayscale.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src, {num amount = 1.0}) {
  num invAmount = 1.0 - amount;
  Image orig = grayscale(new Image.from(src));
  final origRGBA = orig.getBytes();
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

      num tlInt = tl < 0 ? 0.0 : origRGBA[tl] / 255.0;
      num tInt = t < 0 ? 0.0 : origRGBA[t] / 255.0;
      num trInt = tr < 0 ? 0.0 : origRGBA[tr] / 255.0;
      num lInt = l < 0 ? 0.0 : origRGBA[l] / 255.0;
      num rInt = r < rgbaLen ? origRGBA[r] / 255.0 : 0.0;
      num blInt = bl < rgbaLen ? origRGBA[bl] / 255.0 : 0.0;
      num bInt = b < rgbaLen ? origRGBA[b] / 255.0 : 0.0;
      num brInt = br < rgbaLen ? origRGBA[br] / 255.0 : 0.0;

      num h = -tlInt - 2.0 * tInt - trInt + blInt + 2.0 * bInt + brInt;
      num v = -blInt - 2.0 * lInt - tlInt + brInt + 2.0 * rInt + trInt;

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
