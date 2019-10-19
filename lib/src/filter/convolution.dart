import 'dart:math';

import '../color.dart';
import '../image.dart';

/// Apply a 3x3 convolution filter to the [src] image. [filter] should be a
/// list of 9 numbers.
///
/// The rgb channels will be divided by [filterDiv] and add [offset], allowing
/// filters to normalize and offset the filtered pixel value.
Image convolution(Image src, List<num> filter,
    {num div = 1.0, num offset = 0.0}) {
  Image tmp = Image.from(src);

  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      int c = tmp.getPixel(x, y);
      num r = 0.0;
      num g = 0.0;
      num b = 0.0;
      int a = getAlpha(c);
      for (int j = 0, fi = 0; j < 3; ++j) {
        int yv = min(max(y - 1 + j, 0), src.height - 1);
        for (int i = 0; i < 3; ++i, ++fi) {
          int xv = min(max(x - 1 + i, 0), src.width - 1);
          int c2 = tmp.getPixel(xv, yv);
          r += getRed(c2) * filter[fi];
          g += getGreen(c2) * filter[fi];
          b += getBlue(c2) * filter[fi];
        }
      }

      r = (r / div) + offset;
      g = (g / div) + offset;
      b = (b / div) + offset;

      r = (r > 255.0) ? 255.0 : ((r < 0.0) ? 0.0 : r);
      g = (g > 255.0) ? 255.0 : ((g < 0.0) ? 0.0 : g);
      b = (b > 255.0) ? 255.0 : ((b < 0.0) ? 0.0 : b);

      src.setPixel(x, y, getColor(r.toInt(), g.toInt(), b.toInt(), a));
    }
  }

  return src;
}
