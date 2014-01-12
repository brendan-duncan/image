part of image;

/**
 * Set the [brightness] level for the image [src].
 *
 * [brightness] is an offset that is added to the red, green, and blue channels
 * of every pixel.
 */
Image brightness(Image src, int brightness) {
  if (src == null || (brightness < -255 || brightness > 255)) {
    return src;
  }

  if (brightness == 0) {
    return src;
  }

  int np = src.length;
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = r + brightness;
    g = g + brightness;
    b = b + brightness;

    src[i] = getColor(r, g, b, a);
  }

  return src;
}
