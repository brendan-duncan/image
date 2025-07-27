import '../color/channel.dart';
import '../color/color.dart';
import '../font/bitmap_font.dart';
import '../image/image.dart';
import 'blend_mode.dart';
import 'draw_pixel.dart';

/// Draw a string horizontally into [image] at
/// position [x],[y] with the given [color].
/// If [x] is not specified, the string will be centered horizontally.
/// If [y] is not specified, the string will be centered vertically.
///
/// You can load your own font, or use one of the existing ones
/// such as: arial14, arial24, or arial48.
///  Fonts can be create with a tool such as: https://ttf2fnt.com/
Image drawString(Image image, String string,
    {required BitmapFont font,
    int? x,
    int? y,
    Color? color,
    bool rightJustify = false,
    bool wrap = false,
    BlendMode blend = BlendMode.alpha,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (blend == BlendMode.alpha && color?.a == 0) {
    return image;
  }

  var stringWidth = 0;
  var stringHeight = 0;

  final chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;
    stringWidth += ch.xAdvance;
    if (ch.height + ch.yOffset > stringHeight) {
      stringHeight = ch.height + ch.yOffset;
    }
  }

  var sx = x ?? (image.width / 2).round() - (stringWidth / 2).round();
  var sy = y ?? (image.height / 2).round() - (stringHeight / 2).round();

  if (wrap) {
    final sentences = string.split(RegExp(r'\n'));

    for (var sentence in sentences) {
      final words = sentence.split(RegExp(r"\s+"));
      var subString = "";
      var x2 = sx;

      for (var w in words) {
        final ws = StringBuffer()
          ..write(w)
          ..write(' ');
        w = ws.toString();
        final chars = w.codeUnits;
        var wordWidth = 0;
        for (var c in chars) {
          if (c == 10) break;
          if (!font.characters.containsKey(c)) {
            wordWidth += font.base ~/ 2;
            continue;
          }
          final ch = font.characters[c]!;
          wordWidth += ch.xAdvance;
        }
        if ((x2 + wordWidth) > image.width) {
          // If there is a word that won't fit the starting x, stop drawing
          if ((sx == x2) || (sx + wordWidth > image.width)) {
            return image;
          }

          drawString(image, subString,
              font: font,
              x: sx,
              y: sy,
              color: color,
              blend: blend,
              mask: mask,
              maskChannel: maskChannel,
              rightJustify: rightJustify);

          subString = "";
          x2 = sx;
          sy += stringHeight;
          subString += w;
          x2 += wordWidth;
        } else {
          subString += w;
          x2 += wordWidth;
        }

        if (subString.isNotEmpty) {
          drawString(image, subString,
              font: font,
              x: sx,
              y: sy,
              color: color,
              blend: blend,
              mask: mask,
              maskChannel: maskChannel,
              rightJustify: rightJustify);
        }
      }

      sy += stringHeight;
    }

    return image;
  }

  final origX = sx;
  final substrings = string.split(RegExp(r"[\n\r]"));

  // print(substrings);

  for (var ss in substrings) {
    final chars = ss.codeUnits;
    // print("$ss = $chars");
    if (rightJustify == true) {
      for (var c in chars) {
        if (!font.characters.containsKey(c)) {
          sx -= font.base ~/ 2;
          continue;
        }

        final ch = font.characters[c]!;
        sx -= ch.xAdvance;
      }
    }
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        sx += font.base ~/ 2;
        continue;
      }

      final ch = font.characters[c]!;

      final x2 = sx + ch.width;
      final y2 = sy + ch.height;
      final cIter = ch.image.iterator..moveNext();
      for (var yi = sy; yi < y2; ++yi) {
        for (var xi = sx; xi < x2; ++xi, cIter.moveNext()) {
          final p = cIter.current;
          drawPixel(image, xi + ch.xOffset, yi + ch.yOffset, p,
              filter: color,
              blend: blend,
              mask: mask,
              maskChannel: maskChannel);
        }
      }

      sx += ch.xAdvance;
    }

    sy = sy + stringHeight;
    sx = origX;
  }

  return image;
}
