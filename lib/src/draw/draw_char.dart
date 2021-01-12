// @dart=2.11
import '../image.dart';
import '../bitmap_font.dart';
import 'draw_pixel.dart';

/// Draw a single character from [char] horizontally into [image] at position
/// [x],[y] with the given [color].
Image drawChar(Image image, BitmapFont font, int x, int y, String char,
    {int color}) {
  var c = char.codeUnits[0];
  if (!font.characters.containsKey(c)) {
    return image;
  }

  var ch = font.characters[c];
  var x2 = x + ch.width;
  var y2 = y + ch.height;
  var pi = 0;
  for (var yi = y; yi < y2; ++yi) {
    for (var xi = x; xi < x2; ++xi) {
      if (color != null) {
        drawPixel(image, xi, yi, color);
      } else {
        drawPixel(image, xi, yi, ch.image[pi++]);
      }
    }
  }

  return image;
}
