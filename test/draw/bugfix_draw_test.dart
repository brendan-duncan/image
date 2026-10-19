import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Draw bug fixes', () {
    test('fillRect blends a translucent color over an opaque image', () {
      final img = Image(width: 4, height: 4, numChannels: 4)
        ..clear(ColorRgba8(255, 255, 255, 255));
      fillRect(img,
          x1: 0, y1: 0, x2: 3, y2: 3, color: ColorRgba8(0, 0, 0, 160));
      final p = img.getPixel(1, 1);
      // 255 * (1 - 160/255) = 95
      expect(p.r, equals(95));
      expect(p.g, equals(95));
      expect(p.b, equals(95));
      expect(p.a, equals(255));
    });

    test('fillRect blends a translucent color over a transparent image', () {
      final img = Image(width: 4, height: 4, numChannels: 4);
      fillRect(img,
          x1: 0, y1: 0, x2: 3, y2: 3, color: ColorRgba8(255, 0, 0, 160));
      expect(img.getPixel(1, 1).a, equals(160));
    });

    test('fillRect translucent square matches the rounded interior', () {
      final color = ColorRgba8(10, 200, 30, 100);
      final square = Image(width: 40, height: 40, numChannels: 4)
        ..clear(ColorRgba8(50, 60, 70, 200));
      final rounded = square.clone();
      fillRect(square, x1: 0, y1: 0, x2: 39, y2: 39, color: color);
      fillRect(rounded, x1: 0, y1: 0, x2: 39, y2: 39, color: color, radius: 5);
      expect(square.getPixel(20, 20), equals(rounded.getPixel(20, 20)));
    });

    test('fillRect with a mask blends alpha by the mask', () {
      final img = Image(width: 40, height: 40, numChannels: 4);
      final mask = Image(width: 40, height: 40)
        ..clear(ColorRgb8(128, 128, 128));
      fillRect(img,
          x1: 0,
          y1: 0,
          x2: 39,
          y2: 39,
          color: ColorRgba8(255, 0, 0, 255),
          mask: mask);
      expect(img.getPixel(20, 20).a, equals(128));

      final rounded = Image(width: 40, height: 40, numChannels: 4);
      fillRect(rounded,
          x1: 0,
          y1: 0,
          x2: 39,
          y2: 39,
          radius: 5,
          color: ColorRgba8(255, 0, 0, 255),
          mask: mask);
      expect(rounded.getPixel(20, 20).a, equals(128));
    });

    test('drawRect with a radius applies the mask to the edges', () {
      final img = Image(width: 20, height: 20, numChannels: 4);
      // A black mask blocks all drawing.
      final mask = Image(width: 20, height: 20);
      drawRect(img,
          x1: 0,
          y1: 0,
          x2: 19,
          y2: 19,
          radius: 4,
          color: ColorRgba8(255, 255, 255, 255),
          mask: mask);
      for (final p in img) {
        expect(p.a, equals(0), reason: 'pixel ${p.x},${p.y}');
      }
    });

    group('drawString centering', () {
      int lineHeight(BitmapFont font, String s) {
        var h = 0;
        for (final c in s.codeUnits) {
          final ch = font.characters[c];
          if (ch != null && ch.height + ch.yOffset > h) {
            h = ch.height + ch.yOffset;
          }
        }
        return h;
      }

      int lineWidth(BitmapFont font, String s) {
        var w = 0;
        for (final c in s.codeUnits) {
          w += font.characters[c]?.xAdvance ?? 0;
        }
        return w;
      }

      test('multi-line text is centered by its widest line and all lines', () {
        const text = 'Hello World\nHi';
        final centered = Image(width: 200, height: 200);
        drawString(centered, text, font: arial24);

        final w = lineWidth(arial24, 'Hello World');
        final h = lineHeight(arial24, text);
        final expected = Image(width: 200, height: 200);
        drawString(expected, text,
            font: arial24, x: 100 - (w / 2).round(), y: 100 - h);
        expect(centered, equals(expected));
      });

      test('single-line centering is unchanged', () {
        const text = 'Hello World';
        final centered = Image(width: 200, height: 200);
        drawString(centered, text, font: arial24);
        final w = lineWidth(arial24, text);
        final h = lineHeight(arial24, text);
        final expected = Image(width: 200, height: 200);
        drawString(expected, text,
            font: arial24, x: 100 - (w / 2).round(), y: 100 - (h / 2).round());
        expect(centered, equals(expected));
      });

      test('wrapped text is centered by its widest line and all lines', () {
        const text = 'aaaa bbbb cccc dddd eeee';
        final centered = Image(width: 100, height: 200);
        drawString(centered, text, font: arial14, wrap: true);

        // Find the bounds of the drawn pixels.
        var minX = 1000, maxX = -1, minY = 1000, maxY = -1;
        for (final p in centered) {
          if (p.r != 0) {
            final x = p.x, y = p.y;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
        // More than one line was drawn.
        expect(maxY - minY, greaterThan(lineHeight(arial14, text)));
        // The text block is roughly centered.
        expect(((minX + maxX) / 2 - 50).abs(), lessThan(6));
        expect(((minY + maxY) / 2 - 100).abs(), lessThan(8));
      });
    });
  });
}
