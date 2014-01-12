part of image;

/**
 * Draw a single character from [strong] horizontally into [image].
 */
Image drawChar(Image image, BitmapFont font, int x, int y, String string,
               {int color: 0xffffffff}) {
  int c = string.codeUnits[0];
  if (!font.characters.containsKey(c)) {
    return image;
  }

  BitmapFontCharacter ch = font.characters[c];
  int x2 = x + ch.width;
  int y2 = y + ch.height;
  int pi = 0;
  for (int yi = y; yi < y2; ++yi) {
    for (int xi = x; xi < x2; ++xi) {
      int p = ch.image[pi++];
      drawPixel(image, xi, yi, p);
    }
  }

  return image;
}
