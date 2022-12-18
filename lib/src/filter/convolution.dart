import 'dart:math';

import '../image/image.dart';

/// Apply a 3x3 convolution filter to the [src] image. [filter] should be a
/// list of 9 numbers.
///
/// The rgb channels will be divided by [filterDiv] and add [offset], allowing
/// filters to normalize and offset the filtered pixel value.
Image convolution(Image src, List<num> filter,
    { num div = 1.0, num offset = 0.0 }) {
  final tmp = Image.from(src);
  for (var c in tmp) {
    num r = 0.0;
    num g = 0.0;
    num b = 0.0;
    final a = c.a;
    for (var j = 0, fi = 0; j < 3; ++j) {
      final yv = min(max(c.y - 1 + j, 0), src.height - 1);
      for (var i = 0; i < 3; ++i, ++fi) {
        final xv = min(max(c.x - 1 + i, 0), src.width - 1);
        final c2 = tmp.getPixel(xv, yv);
        r += c2.r * filter[fi];
        g += c2.g * filter[fi];
        b += c2.b * filter[fi];
      }
    }

    r = ((r / div) + offset).clamp(0, 255);
    g = ((g / div) + offset).clamp(0, 255);
    b = ((b / div) + offset).clamp(0, 255);

    src.setPixelColor(c.x, c.y, r, g, b, a);
  }

  return src;
}
