part of image;

/**
 * Draw a string horizontally into [image].
 *
 * You can load your own font, or use one of the existing ones
 * such as: [arial_14], [arial_24], or [arial_48].
 */
Image drawString(Image image, BitmapFont font, int x, int y, String string,
                 {int color: 0xffffffff}) {
  int ca = getAlpha(color);
  if (ca == 0) {
    return image;
  }

  double da = ca / 255.0;
  double dr = getRed(color) / 255.0;
  double dg = getGreen(color) / 255.0;
  double db = getBlue(color) / 255.0;

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
        p = getColor((getRed(p) * dr).toInt(),
                     (getGreen(p) * dg).toInt(),
                     (getBlue(p) * db).toInt(),
                     (getAlpha(p) * da).toInt());

        image.setPixelBlend(xi + ch.xoffset, yi + ch.yoffset, p);
      }
    }

    x += ch.xadvance;
  }

  return image;
}
