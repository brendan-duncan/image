part of image;

/**
 * Invert [src] image.
 */
Image negate(Image src) {
  int np = src.buffer.length;
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    src.buffer[i] = getColor(255 - r, 255 - g, 255 - b, a);
  }

  return src;
}
