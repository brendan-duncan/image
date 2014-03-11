part of image;

/**
 * Draw a single character from [char] horizontally into [image] at position
 * [x],[y] with the given [color].
 */
Image drawChar(Image image, BitmapFont font, int x, int y, String char,
               {int color: 0xffffffff}) {
  int c = char.codeUnits[0];
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
