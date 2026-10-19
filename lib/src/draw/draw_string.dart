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
///
/// If [linearBlend] is true, partly transparent and antialiased pixels are
/// blended as linear light, the colors taken as sRGB, which is slower but
/// keeps thin and soft edges from looking too dark.
Image drawString(Image image, String string,
    {required BitmapFont font,
    int? x,
    int? y,
    Color? color,
    bool rightJustify = false,
    bool wrap = false,
    BlendMode blend = BlendMode.alpha,
    bool linearBlend = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (blend == BlendMode.alpha && color?.a == 0) {
    return image;
  }

  var stringHeight = 0;

  final chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;
    if (ch.height + ch.yOffset > stringHeight) {
      stringHeight = ch.height + ch.yOffset;
    }
  }

  // The width of a line of text, used to center it.
  int lineWidth(String line) {
    var w = 0;
    for (var c in line.codeUnits) {
      final ch = font.characters[c];
      if (ch != null) {
        w += ch.xAdvance;
      }
    }
    return w;
  }

  // Center a block of [lines] lines, the widest of which is [width] wide.
  int centerX(int width) => (image.width / 2).round() - (width / 2).round();
  int centerY(int lines) =>
      (image.height / 2).round() - ((stringHeight * lines) / 2).round();

  if (wrap) {
    // Break the text into lines first, so the block of lines can be centered
    // when x or y is not given.
    final startX = x ?? 0;
    final lines = <String>[];
    var stopped = false;

    final sentences = string.split(RegExp(r'\n'));

    for (var sentence in sentences) {
      final words = sentence.split(RegExp(r"\s+"));
      final line = StringBuffer();
      var x2 = startX;

      for (final w in words) {
        final word = '$w ';
        final chars = word.codeUnits;
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
          if ((startX == x2) || (startX + wordWidth > image.width)) {
            if (line.isNotEmpty) {
              lines.add(line.toString());
            }
            stopped = true;
            break;
          }

          lines.add(line.toString());
          line.clear();
          x2 = startX;
        }
        line.write(word);
        x2 += wordWidth;
      }

      if (stopped) {
        break;
      }

      if (line.isNotEmpty) {
        lines.add(line.toString());
      }
    }

    var widest = 0;
    for (final line in lines) {
      final w = lineWidth(line.trimRight());
      if (w > widest) {
        widest = w;
      }
    }

    final sx = x ?? centerX(widest);
    var sy = y ?? centerY(lines.length);

    // Each line is drawn once, rather than redrawing it for each word, which
    // would take quadratic time.
    for (final line in lines) {
      drawString(image, line,
          font: font,
          x: sx,
          y: sy,
          color: color,
          blend: blend,
          linearBlend: linearBlend,
          mask: mask,
          maskChannel: maskChannel,
          rightJustify: rightJustify);
      sy += stringHeight;
    }

    return image;
  }

  final substrings = string.split(RegExp(r"[\n\r]"));

  var stringWidth = 0;
  for (final ss in substrings) {
    final w = lineWidth(ss);
    if (w > stringWidth) {
      stringWidth = w;
    }
  }

  var sx = x ?? centerX(stringWidth);
  var sy = y ?? centerY(substrings.length);

  final origX = sx;

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
              linearBlend: linearBlend,
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
