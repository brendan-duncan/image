import 'dart:typed_data';
import '../bitmap_font.dart';
import '../color.dart';
import '../image.dart';
import 'draw_pixel.dart';

var _r_lut = Uint8List(256);
var _g_lut = Uint8List(256);
var _b_lut = Uint8List(256);
var _a_lut = Uint8List(256);

/**
 * Draw a string horizontally into [image] horizontally into [image] at position
 * [x],[y] with the given [color].
 *
 * You can load your own font, or use one of the existing ones
 * such as: [arial_14], [arial_24], or [arial_48].
 */
Image drawString(Image image, BitmapFont font, int x, int y, String string,
    {int color = 0xffffffff}) {
  if (color != 0xffffffff) {
    int ca = getAlpha(color);
    if (ca == 0) {
      return image;
    }
    double da = ca / 255.0;
    double dr = getRed(color) / 255.0;
    double dg = getGreen(color) / 255.0;
    double db = getBlue(color) / 255.0;
    for (int i = 1; i < 256; ++i) {
      _r_lut[i] = (dr * i).toInt();
      _g_lut[i] = (dg * i).toInt();
      _b_lut[i] = (db * i).toInt();
      _a_lut[i] = (da * i).toInt();
    }
  }

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
        int p = ch.image[pi++];
        if (color != 0xffffffff) {
          p = getColor(_r_lut[getRed(p)], _g_lut[getGreen(p)],
              _b_lut[getBlue(p)], _a_lut[getAlpha(p)]);
        }
        drawPixel(image, xi + ch.xoffset, yi + ch.yoffset, p);
      }
    }

    x += ch.xadvance;
  }

  return image;
}
