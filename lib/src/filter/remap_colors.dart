part of image;

/**
 * Remap the color channels of the image.
 * [red], [green], [blue] and [alpha] should be set to one of the following:
 * [RED], [GREEN], [BLUE] or [ALPHA].  For example,
 * remapColors(src, red: GREEN, green: RED);
 * will swap the red and green channels of the image.
 */
Image remapColors(Image src,
   {int red: RED,
    int green: GREEN,
    int blue: BLUE,
    int alpha: ALPHA}) {
  final int np = src.length;
  List<int> l = [0, 0, 0, 0, 0];
  for (int i = 0; i < np; ++i) {
    int c = src[i];
    l[0] = getRed(c);
    l[1] = getGreen(c);
    l[2] = getBlue(c);
    l[3] = getAlpha(c);

    if (red == LUMINANCE || green == LUMINANCE || blue == LUMINANCE ||
        alpha == LUMINANCE) {
      l[4] = luminance(c);
    }

    src[i] = getColor(l[red], l[green], l[blue], l[alpha]);
  }

  return src;
}
