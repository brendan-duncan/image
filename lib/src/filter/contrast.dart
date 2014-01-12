part of image;

/**
 * Set the [contrast] level for the image [src].
 *
 * [contrast] values below 100 will decrees the contrast of the image,
 * and values above 100 will increase the contrast.  A contrast of of 100
 * will have no affect.
 */
Image contrast(Image src, num contrast) {
  if (src == null || contrast == 100.0) {
    return src;
  }

  contrast = contrast / 100.0;
  contrast = contrast * contrast;

  int np = src.length;
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    r = (((((r / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();
    g = (((((g / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();
    b = (((((b / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt();

    src[i] = getColor(r, g, b, a);
  }

  return src;
}
