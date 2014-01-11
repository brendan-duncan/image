part of image;

/**
 * Convert the image to grayscale.
 */
Image grayscale(Image src) {
  int np = src.buffer.length;
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
    src.buffer[i] = getColor(r, r, r, a);
  }

  return src;
}
