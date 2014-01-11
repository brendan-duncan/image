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
  int np = src.buffer.length;
  List<int> l = [0, 0, 0, 0];
  for (int i = 0; i < np; ++i) {
    int c = src.buffer[i];
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);

    l[red] = r;
    l[green] = g;
    l[blue] = b;
    l[alpha] = a;

    src.buffer[i] = getColor(l[0], l[1], l[2], l[3]);
  }

  return src;
}
