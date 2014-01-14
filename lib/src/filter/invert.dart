part of image;

/**
 * Invert the colors of the [src] image.
 */
Image invert(Image src) {
  int np = src.length;
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);
    src[i] = getColor(255 - r, 255 - g, 255 - b, a);
  }

  return src;
}
