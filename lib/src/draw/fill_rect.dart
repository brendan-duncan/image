part of image;

/**
 * Fill a rectangle in the image [src] with the [color].
 */
Image fillRect(Image src, int x, int y, int w, int h, int color) {
  for (int yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (int xi = 0, sx = x; xi < w; ++xi, ++sx) {
      src.setPixel(sx, sy, color);
    }
  }
}
