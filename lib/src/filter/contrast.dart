part of image;

/**
 * Set the [contrast] level for the image [src].
 */
Image contrast(Image src, num contrast) {
  if (src == null) {
    return src;
  }

  contrast = contrast / 100.0;
  contrast = contrast * contrast;

  int np = src.buffer.length;
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = (((((r / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();
    g = (((((g / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();
    b = (((((b / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();

    r = (r > 255) ? 255 : ((r < 0) ? 0 : r);
    g = (g > 255) ? 255 : ((g < 0) ? 0 : g);
    b = (b > 255) ? 255 : ((b < 0) ? 0 : b);

    src.buffer[i] = getColor(r, g, b, a);
  }

  return src;
}
