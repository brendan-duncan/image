part of image;

/**
 * Add the [red], [green], [blue] and [alpha] values to the [src] image
 * colors, a per-channel brightness.
 */
Image colorOffset(Image src, int red, int green, int blue, int alpha) {
  int np = src.length;
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = r + red;
    g = g + green;
    b = b + blue;
    a = a + alpha;

    src[i] = getColor(r, g, b, a);
  }

  return src;
}
