part of image;

/**
 * Draw a string horizontally into [image].
 *
 * You can load your own font, or use one of the existing ones
 * such as: [arial_14], [arial_24], or [arial_48].
 */
Image drawString(Image image, BitmapFont font, int x, int y, String string,
                 {int color: 0xffffffff}) {
  int ca = alpha(color);
  if (ca == 0) {
    return image;
  }

  double da = ca / 255.0;
  double dr = red(color) / 255.0;
  double dg = green(color) / 255.0;
  double db = blue(color) / 255.0;

  List<int> chars = string.codeUnits;
  for (int c in chars) {
    if (!font.characters.containsKey(c)) {
      x += font.base ~/ 2;
      continue;
    }

    BitmapFontCharacter ch = font.characters[c];

    int x2 = x + ch.width;
    int y2 = y + ch.height;
    int pi = 0;
    for (int yi = y; yi < y2; ++yi) {
      for (int xi = x; xi < x2; ++xi) {
        int p = ch.uint32Data[pi++];
        p = getColor((red(p) * dr).toInt(),
                     (green(p) * dg).toInt(),
                     (blue(p) * db).toInt(),
                     (alpha(p) * da).toInt());

        drawPixel(image, xi + ch.xoffset, yi + ch.yoffset, p);
      }
    }

    x += ch.xadvance;
  }

  return image;
}
