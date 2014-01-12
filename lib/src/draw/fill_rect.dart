part of image;

/**
 * Fill a rectangle in the image [src] with the [color].
 */
Image fillRect(Image src, int x1, int y1, int x2, int y2, int color) {
  int x0 = Math.min(x1, x2);
  int y0 = Math.min(y1, y2);
  x1 = Math.max(x1, x2);
  y1 = Math.max(y1, y2);
  for (int sy = y0; sy <= y1; ++sy) {
    for (int sx = x0; sx <= x1; ++sx) {
      src.setPixel(sx, sy, color);
    }
  }
}
