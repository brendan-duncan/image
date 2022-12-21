import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint8.dart';
import '../font/bitmap_font.dart';
import '../image/image.dart';
import 'draw_pixel.dart';

final _rLut = Uint8List(256);
final _gLut = Uint8List(256);
final _bLut = Uint8List(256);
final _aLut = Uint8List(256);

/// Draw a string horizontally into [image] horizontally into [image] at
/// position [x],[y] with the given [color].
///
/// You can load your own font, or use one of the existing ones
/// such as: arial14, arial24, or arial48.
///  Fonts can be create with a tool such as: https://ttf2fnt.com/
void drawString(Image image, BitmapFont font, int x, int y, String string,
    {Color? color, bool rightJustify = false}) {
  if (color != null) {
    final ca = color.a;
    if (ca == 0) {
      return;
    }
    final da = ca / 255.0;
    final dr = color.r / 255.0;
    final dg = color.g / 255.0;
    final db = color.b / 255.0;
    for (var i = 1; i < 256; ++i) {
      _rLut[i] = (dr * i).toInt();
      _gLut[i] = (dg * i).toInt();
      _bLut[i] = (db * i).toInt();
      _aLut[i] = (da * i).toInt();
    }
  }

  final stringHeight = _findStringHeight(font, string);
  final origX = x;
  final substrings = string.split(new RegExp(r"[(\n|\r)]"));
  final _c = ColorRgba8();

  for (var ss in substrings) {
    final chars = ss.codeUnits;
    if (rightJustify == true) {
      for (var c in chars) {
        if (!font.characters.containsKey(c)) {
          x -= font.base ~/ 2;
          continue;
        }

        final ch = font.characters[c]!;
        x -= ch.xadvance;
      }
    }
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        x += font.base ~/ 2;
        continue;
      }

      final ch = font.characters[c]!;

      final x2 = x + ch.width;
      final y2 = y + ch.height;
      final cIter = ch.image.iterator..moveNext();
      for (var yi = y; yi < y2; ++yi) {
        for (var xi = x; xi < x2; ++xi, cIter.moveNext()) {
          final p = cIter.current;
          if (color != null) {
            _c..r = _rLut[p.r as int]
              ..g = _gLut[p.g as int]
              ..b = _bLut[p.b as int]
              ..a = _aLut[p.a as int];
            drawPixel(image, xi + ch.xoffset, yi + ch.yoffset, _c);
          } else {
            drawPixel(image, xi + ch.xoffset, yi + ch.yoffset, p);
          }
        }
      }

      x += ch.xadvance;
    }

    y = y+stringHeight;
    x = origX;
  }
}

/// Same as drawString except the strings will wrap around to create multiple
/// lines. You can load your own font, or use one of the existing ones
/// such as: arial14, arial24, or arial48.
void drawStringWrap(Image image, BitmapFont font, int x, int y, String string,
    {Color? color}) {

  final stringHeight = _findStringHeight(font, string);
  final words = string.split(new RegExp(r"\s+"));
  var subString = "";
  var x2 = x;

  for (var w in words) {
    final ws = StringBuffer()
    ..write(w)
    ..write(' ');
    w = ws.toString();
    final chars = w.codeUnits;
    var wordWidth = 0;
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        wordWidth += font.base ~/ 2;
        continue;
      }
      final ch = font.characters[c]!;
      wordWidth += ch.xadvance;
    }
    if ((x2 + wordWidth) > image.width) {
      // If there is a word that won't fit the starting x, stop drawing
      if ((x == x2) || (x + wordWidth > image.width)) {
        return;
      }

      drawString(image, font, x, y, subString, color: color);

      subString = "";
      x2 = x;
      y += stringHeight;
      subString += w;
      x2 += wordWidth;
    } else {
      subString += w;
      x2 += wordWidth;
    }

    if (subString.length > 0) {
      drawString(image, font, x, y, subString, color: color);
    }
  }
}

/// Draw a string horizontally into [image] at position
/// [x],[y] with the given [color].
/// If x is omitted text is automatically centered into [image]
/// If y is omitted text is automatically centered into [image].
/// If both x and y are provided it has the same behaviour of drawString method.
///
/// You can load your own font, or use one of the existing ones
/// such as: arial14, arial24, or arial48.
void drawStringCentered(Image image, BitmapFont font, String string,
    {int? x, int? y, Color? color}) {
  var stringWidth = 0;
  var stringHeight = 0;

  if (x == null || y == null) {
    final chars = string.codeUnits;
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        continue;
      }
      final ch = font.characters[c]!;
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

  drawString(image, font, xPos, yPos, string, color: color);
}

int _findStringHeight(BitmapFont font, String string) {
  var stringHeight = 0;
  final chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;
    if (ch.height + ch.yoffset > stringHeight) {
      stringHeight = ch.height + ch.yoffset;
    }
  }
  return (stringHeight * 1.05).round();
}
