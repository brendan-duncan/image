import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillFlood: seed pixel becomes fill color', () {
      // A plain black image: flood-filling from (5,5) should paint the whole
      // image because every pixel has the same color as the seed.
      final img = solidImage(20, 20, ColorRgb8(0, 0, 0));
      final fillColor = ColorRgb8(0, 200, 0);
      fillFlood(img, x: 5, y: 5, color: fillColor);
      // seed pixel itself must now be the fill color
      final seed = img.getPixel(5, 5);
      expect(seed.r, equals(0));
      expect(seed.g, equals(200));
      expect(seed.b, equals(0));
    });

    test('fillFlood: connected region is filled; separated region is not', () {
      // Draw a vertical dividing line in the middle of a 40-wide image.
      // Flood-fill from the left side must not cross to the right side.
      final img = Image(width: 40, height: 20);
      // draw a solid red vertical wall at x=19..20
      for (var y = 0; y < 20; y++) {
        img
          ..setPixel(19, y, ColorRgb8(255, 0, 0))
          ..setPixel(20, y, ColorRgb8(255, 0, 0));
      }
      final fillColor = ColorRgb8(0, 0, 255);
      fillFlood(img, x: 5, y: 10, color: fillColor, threshold: 0);

      // a pixel on the left side should be filled
      final left = img.getPixel(5, 10);
      expect(left.b, equals(255),
          reason: 'left region should be filled with blue');

      // a pixel on the right side must remain black (not crossed the wall)
      final right = img.getPixel(35, 10);
      expect(right.r, equals(0));
      expect(right.g, equals(0));
      expect(right.b, equals(0));
    });

    test('fillFlood: image dimensions unchanged after fill', () {
      final img = Image(width: 30, height: 30);
      fillFlood(img, x: 15, y: 15, color: ColorRgb8(128, 0, 128));
      expect(img.width, equals(30));
      expect(img.height, equals(30));
    });

    test('fillFlood', () async {
      final img = Image(width: 100, height: 100);
      drawCircle(img, x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0));
      fillFlood(img, x: 50, y: 50, color: ColorRgb8(0, 255, 0), threshold: 1);

      File('$testOutputPath/draw/fillFlood.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(img));

      final mask = Command()
        ..createImage(width: 100, height: 100)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(x: 50, y: 50, radius: 25, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 5);

      await (Command()
            ..createImage(width: 100, height: 100)
            ..drawCircle(x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0))
            ..fillFlood(
              x: 50,
              y: 50,
              color: ColorRgb8(0, 255, 0),
              threshold: 1,
              mask: mask,
            )
            ..writeToFile('$testOutputPath/draw/fillFlood_mask.png'))
          .execute();
    });
  });
}
