part of image;

/**
 * Add the [red], [green], [blue] and [alpha] values to the [src] image
 * colors, a per-channel brightness.
 */
Image colorOffset(Image src, int red, int green, int blue, int alpha) {
  int np = src.buffer.length;
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = r + red;
    g = g + green;
    b = b + blue;
    a = a + alpha;

    r = (r > 255) ? 255 : ((r < 0) ? 0 : r);
    g = (g > 255) ? 255 : ((g < 0) ? 0 : g);
    b = (b > 255) ? 255 : ((b < 0) ? 0 : b);
    a = (a > 255) ? 255 : ((a < 0) ? 0 : a);

    src.buffer[i] = getColor(r, g, b, a);
  }

  return src;
}
