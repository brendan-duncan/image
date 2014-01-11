part of image;

/**
 * Returns a croped copy of [src].
 */
Image copyCrop(Image src, int x, int y, int w, int h) {
  Image dst = new Image(w, h, src.format);

  for (int yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (int xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}
