import '../color/color.dart';
import '../font/bitmap_font.dart';
import '../image/image.dart';
import 'draw_pixel.dart';

/// Draw a single character from [char] horizontally into [image] at position
/// [x],[y] with the given [color].
void drawChar(Image image, BitmapFont font, int x, int y, String char,
    {Color? color}) {
  final c = char.codeUnits[0];
  if (!font.characters.containsKey(c)) {
    return;
  }

  final ch = font.characters[c]!;
  final x2 = x + ch.width;
  final y2 = y + ch.height;
  final cIter = ch.image.iterator..moveNext();

  for (var yi = y; yi < y2; ++yi) {
    for (var xi = x; xi < x2; ++xi, cIter.moveNext()) {
      final cp = cIter.current;
      if (color != null) {
        drawPixel(image, xi, yi, color, cp.a / cp.maxChannelValue);
      } else {
        drawPixel(image, xi, yi, cIter.current);
      }
    }
  }

  return;
}
