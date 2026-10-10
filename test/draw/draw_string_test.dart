import 'dart:io';
import 'dart:math' show max;

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// The width (sum of advances) and height of [string] drawn with [font].
(int, int) _stringSize(BitmapFont font, String string) {
  var w = 0;
  var h = 0;
  for (final c in string.codeUnits) {
    final ch = font.characters[c];
    if (ch != null) {
      w += ch.xAdvance;
      h = max(h, ch.height + ch.yOffset);
    }
  }
  return (w, h);
}

/// Whether ([x],[y]) is in the box (left, top, width, height), with a small
/// margin for glyphs that overhang their advance.
bool _inBox(num x, num y, (int, int, int, int) box) {
  const m = 2;
  final (l, t, w, h) = box;
  return x >= l - m && x < l + w + m && y >= t - m && y < t + h + m;
}

void main() {
  group('Draw', () {
    test('drawString wrap draws each line once', () {
      // Drawing a line more than once would blend its glyphs over themselves.
      final color = ColorRgba8(255, 255, 255, 128);
      final wrapped = Image(width: 100, height: 100);
      drawString(wrapped, 'aaa bbb ccc ddd',
          font: arial14, x: 0, y: 0, color: color, wrap: true);
      final (_, lineHeight) = _stringSize(arial14, 'aaa bbb ccc ddd');
      final lines = Image(width: 100, height: 100);
      drawString(lines, 'aaa bbb ccc ',
          font: arial14, x: 0, y: 0, color: color);
      drawString(lines, 'ddd ',
          font: arial14, x: 0, y: lineHeight, color: color);
      expect(wrapped, equals(lines));
    });

    test('drawString', () {
      final i0 = Image(width: 256, height: 256)..clear(ColorRgb8(128, 128, 0));
      drawString(
        i0,
        "Hello",
        font: arial24,
        x: 50,
        y: 50,
        color: ColorRgba8(255, 0, 0, 128),
      );
      drawString(
        i0,
        "Right Justified",
        font: arial24,
        x: 200,
        y: 80,
        rightJustify: true,
      );
      drawString(i0, "Centered", font: arial24);

      File('$testOutputPath/draw/drawString.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // The bounds of each string, from the font metrics.
      final (helloW, helloH) = _stringSize(arial24, 'Hello');
      final (rightW, rightH) = _stringSize(arial24, 'Right Justified');
      final (centerW, centerH) = _stringSize(arial24, 'Centered');
      final hello = (50, 50, helloW, helloH);
      final right = (200 - rightW, 80, rightW, rightH);
      final centered = (
        128 - (centerW / 2).round(),
        128 - (centerH / 2).round(),
        centerW,
        centerH
      );

      final changed = {hello: 0, right: 0, centered: 0};
      for (final p in i0) {
        if (p.r == 128 && p.g == 128 && p.b == 0) {
          continue;
        }
        final box = changed.keys.where((b) => _inBox(p.x, p.y, b)).firstOrNull;
        expect(box, isNotNull,
            reason: 'pixel ${p.x},${p.y} changed outside the text');
        changed[box!] = changed[box]! + 1;
        if (box == hello) {
          // Half transparent red text pulls the background toward red.
          expect(p.r, greaterThan(128), reason: 'hello ${p.x},${p.y}');
          expect(p.g, lessThan(128), reason: 'hello ${p.x},${p.y}');
          expect(p.b, equals(0), reason: 'hello ${p.x},${p.y}');
        } else {
          // Text with no color is drawn white.
          expect(p.r, greaterThan(128), reason: 'white ${p.x},${p.y}');
          expect(p.g, greaterThan(128), reason: 'white ${p.x},${p.y}');
          expect(p.b, greaterThan(0), reason: 'white ${p.x},${p.y}');
        }
      }
      // Every string drew a reasonable number of glyph pixels.
      for (final e in changed.entries) {
        expect(e.value, greaterThan(e.key.$3 * 2),
            reason: 'pixels drawn in ${e.key}');
      }
    });

    test('drawString: some pixels change from background after drawing', () {
      // A blank white image with text drawn in black must have at least one
      // pixel that differs from the background.
      final bg = ColorRgb8(255, 255, 255);
      final img = Image(width: 200, height: 60)..clear(bg);
      drawString(img, 'Hi',
          font: arial24, x: 10, y: 10, color: ColorRgb8(0, 0, 0));

      var changed = 0;
      for (final p in img) {
        if (p.r != bg.r || p.g != bg.g || p.b != bg.b) changed++;
      }
      // at least one glyph pixel must have been painted
      expect(changed, greaterThan(0),
          reason: 'drawString must paint at least one pixel');
    });

    test('drawString: image dimensions are unchanged', () {
      final img = Image(width: 128, height: 64);
      drawString(img, 'Test', font: arial24, x: 0, y: 0);
      expect(img.width, equals(128));
      expect(img.height, equals(64));
    });

    test('drawString: pixels far from text region stay background', () {
      // Draw a short string in the top-left corner; the bottom-right corner
      // must remain the original background color.
      final bg = ColorRgb8(64, 64, 64);
      final img = Image(width: 200, height: 200)..clear(bg);
      drawString(img, 'A',
          font: arial24, x: 2, y: 2, color: ColorRgb8(255, 255, 255));
      // pixel at the far corner should still be the background
      final p = img.getPixel(199, 199);
      expect(p.r, equals(bg.r));
      expect(p.g, equals(bg.g));
      expect(p.b, equals(bg.b));
    });
  });
}
