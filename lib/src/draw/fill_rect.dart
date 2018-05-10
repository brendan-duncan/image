import 'dart:math' as Math;

import '../image.dart';
import 'draw_pixel.dart';

/**
 * Fill a rectangle in the image [src] with the given [color] with the corners
 * [x1],[y1] and [x2],[y2].
 */
Image fillRect(Image src, int x1, int y1, int x2, int y2, int color) {
  int x0 = Math.min(x1, x2);
  int y0 = Math.min(y1, y2);
  x1 = Math.max(x1, x2);
  y1 = Math.max(y1, y2);
  for (int sy = y0; sy <= y1; ++sy) {
    for (int sx = x0; sx <= x1; ++sx) {
      drawPixel(src, sx, sy, color);
    }
  }

  return src;
}
