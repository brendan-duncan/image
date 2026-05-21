import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
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
    });

    test('drawString: some pixels change from background after drawing', () {
      // A blank white image with text drawn in black must have at least one
      // pixel that differs from the background.
      final bg = ColorRgb8(255, 255, 255);
      final img = Image(width: 200, height: 60)..clear(bg);
      drawString(img, 'Hi', font: arial24, x: 10, y: 10,
          color: ColorRgb8(0, 0, 0));

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
      drawString(img, 'A', font: arial24, x: 2, y: 2,
          color: ColorRgb8(255, 255, 255));
      // pixel at the far corner should still be the background
      final p = img.getPixel(199, 199);
      expect(p.r, equals(bg.r));
      expect(p.g, equals(bg.g));
      expect(p.b, equals(bg.b));
    });
  });
}
