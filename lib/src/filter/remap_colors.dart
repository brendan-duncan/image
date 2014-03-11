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

  List<int> l = [0, 0, 0, 0, 0];
  var p = src.getBytes();
  for (int i = 0, len = p.length; i < len; i += 4) {
    l[0] = p[i];
    l[1] = p[i + 1];
    l[2] = p[i + 2];
    l[3] = p[i + 3];
    if (red == LUMINANCE || green == LUMINANCE || blue == LUMINANCE ||
        alpha == LUMINANCE) {
      l[4] = getLuminanceRGB(l[0], l[1], l[2]);
    }
    p[i] = l[red];
    p[i + 1] = l[green];
    p[i + 2] = l[blue];
    p[i + 3] = l[alpha];
  }

  return src;
}
