part of image;

/**
 * Convert the image to grayscale.
 */
Image grayscale(Image src) {
  final int np = src.length;
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    int a = getAlpha(c);
    int l = getLuminance(c);
    src[i] = getColor(l, l, l, a);
  }

  return src;
}
