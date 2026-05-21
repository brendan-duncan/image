import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawChar', () async {
      final cmd = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(128, 128, 0))
        ..drawChar("H", font: arial24, x: 50, y: 50)
        ..drawChar(
          "e",
          font: arial24,
          x: 70,
          y: 70,
          color: ColorRgba8(255, 0, 0, 255),
        )
        ..drawChar(
          "l",
          font: arial24,
          x: 90,
          y: 90,
          color: ColorRgba8(0, 255, 0, 255),
        )
        ..drawChar(
          "l",
          font: arial24,
          x: 110,
          y: 110,
          color: ColorRgba8(0, 0, 255, 255),
        )
        ..drawChar(
          "o",
          font: arial24,
          x: 130,
          y: 130,
          color: ColorRgba8(255, 0, 0, 128),
        )
        ..writeToFile('$testOutputPath/draw/drawChar.png');

      final image = await cmd.getImageThread();
      expect(image, isNotNull);
      expect(image?.width, equals(256));
      expect(image?.height, equals(256));
    });

    test('drawChar: some pixels change from background after drawing', () {
      // Draw a known character on a solid background; at least one pixel must
      // differ from the background, proving the glyph was rendered.
      final bg = ColorRgb8(0, 0, 0);
      final img = Image(width: 64, height: 64)..clear(bg);
      drawChar(img, 'A',
          font: arial24, x: 5, y: 5, color: ColorRgb8(255, 255, 255));

      var changed = 0;
      for (final p in img) {
        if (p.r != bg.r || p.g != bg.g || p.b != bg.b) changed++;
      }
      // the glyph must have painted at least one pixel
      expect(changed, greaterThan(0),
          reason: 'drawChar must paint at least one pixel');
    });

    test('drawChar: image dimensions are unchanged', () {
      final img = Image(width: 64, height: 64);
      drawChar(img, 'B', font: arial24, x: 10, y: 10);
      expect(img.width, equals(64));
      expect(img.height, equals(64));
    });

    test('drawChar: pixel far from glyph stays background', () {
      // Draw a character in the top-left; the far corner must be untouched.
      final bg = ColorRgb8(50, 100, 150);
      final img = Image(width: 200, height: 200)..clear(bg);
      drawChar(img, 'X',
          font: arial24, x: 2, y: 2, color: ColorRgb8(255, 0, 0));
      final p = img.getPixel(199, 199);
      expect(p.r, equals(bg.r));
      expect(p.g, equals(bg.g));
      expect(p.b, equals(bg.b));
    });
  });
}
