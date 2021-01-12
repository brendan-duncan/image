
import 'dart:typed_data';
import '../bitmap_font.dart';
import '../color.dart';
import '../image.dart';
import 'draw_pixel.dart';

var _r_lut = Uint8List(256);
var _g_lut = Uint8List(256);
var _b_lut = Uint8List(256);
var _a_lut = Uint8List(256);

/// Draw a string horizontally into [image] horizontally into [image] at position
/// [x],[y] with the given [color].
///
/// You can load your own font, or use one of the existing ones
/// such as: [arial_14], [arial_24], or [arial_48].
Image drawString(Image image, BitmapFont font, int x, int y, String string,
    {int color = 0xffffffff}) {
  if (color != 0xffffffff) {
    var ca = getAlpha(color);
    if (ca == 0) {
      return image;
    }
    num da = ca / 255.0;
    num dr = getRed(color) / 255.0;
    num dg = getGreen(color) / 255.0;
    num db = getBlue(color) / 255.0;
    for (var i = 1; i < 256; ++i) {
      _r_lut[i] = (dr * i).toInt();
      _g_lut[i] = (dg * i).toInt();
      _b_lut[i] = (db * i).toInt();
      _a_lut[i] = (da * i).toInt();
    }
  }

  var chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      x += font.base ~/ 2;
      continue;
    }

    var ch = font.characters[c]!;

    var x2 = x + ch.width;
    var y2 = y + ch.height;
    var pi = 0;
    for (var yi = y; yi < y2; ++yi) {
      for (var xi = x; xi < x2; ++xi) {
        var p = ch.image[pi++];
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

/// Draw a string horizontally into [image] at position
/// [x],[y] with the given [color].
/// If x is omitted text is automatically centered into [image]
/// If y is omitted text is automatically centered into [image].
/// If both x and y are provided it has the same behaviour of drawString method.
///
/// You can load your own font, or use one of the existing ones
/// such as: [arial_14], [arial_24], or [arial_48].
Image drawStringCentered(Image image, BitmapFont font, String string,
    {int? x, int? y, int color = 0xffffffff}) {
  var stringWidth = 0;
  var stringHeight = 0;

  if (x == null || y == null) {
    var chars = string.codeUnits;
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        continue;
      }
      var ch = font.characters[c]!;
      stringWidth += ch.xadvance;
      if (ch.height + ch.yoffset > stringHeight) {
        stringHeight = ch.height + ch.yoffset;
      }
    }
  }

  int xPos, yPos;
  if (x == null) {
    xPos = (image.width / 2).round() - (stringWidth / 2).round();
  } else {
    xPos = x;
  }
  if (y == null) {
    yPos = (image.height / 2).round() - (stringHeight / 2).round();
  } else {
    yPos = y;
  }

  return drawString(image, font, xPos, yPos, string, color: color);
}
