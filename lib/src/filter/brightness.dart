part of image;

/**
 * Set the [brightness] level for the image [src].
 */
Image brightness(Image src, int brightness) {
  if (src == null || (brightness < -255 || brightness > 255)) {
    return src;
  }

  if (brightness == 0) {
    return src;
  }

  int np = src.buffer.length;
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = r + brightness;
    g = g + brightness;
    b = b + brightness;

    r = (r > 255) ? 255 : ((r < 0) ? 0 : r);
    g = (g > 255) ? 255 : ((g < 0) ? 0 : g);
    b = (b > 255) ? 255 : ((b < 0) ? 0 : b);

    src.buffer[i] = getColor(r, g, b, a);
  }

  return src;
}
