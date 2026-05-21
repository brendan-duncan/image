import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  final r = Random();
  group('Draw', () {
    test('drawPixel.uint8', () {
      final i0 = Image(width: 256, height: 256);
      for (var i = 0; i < 10000; ++i) {
        final x = r.nextInt(i0.width - 1);
        final y = r.nextInt(i0.height - 1);
        drawPixel(i0, x, y, ColorRgb8(x, y, 0));
      }
      File('$testOutputPath/draw/drawPixel.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('drawPixel sets the exact pixel to the given color', () {
      final image = Image(width: 10, height: 10);

      // The drawn pixel has the exact color specified.
      drawPixel(image, 3, 4, ColorRgb8(255, 0, 128), blend: BlendMode.direct);
      expect(image.getPixel(3, 4), equals([255, 0, 128]),
          reason: 'pixel (3,4) should be the drawn color');

      // A pixel that was not drawn retains the background (black).
      expect(image.getPixel(0, 0), equals([0, 0, 0]),
          reason: 'undrawn pixel (0,0) should remain black');
    });

    test('drawPixel returns the image (mutates in place)', () {
      final image = Image(width: 5, height: 5);
      // drawPixel returns the same image object.
      final result = drawPixel(
          image, 2, 2, ColorRgb8(10, 20, 30), blend: BlendMode.direct);
      expect(identical(result, image), isTrue,
          reason: 'drawPixel should return the same Image object');
    });

    test('drawPixel out-of-bounds does not throw and leaves image unchanged',
        () {
      final image = Image(width: 4, height: 4);
      // These should be no-ops; no exception expected.
      drawPixel(image, -1, 0, ColorRgb8(255, 0, 0));
      drawPixel(image, 0, -1, ColorRgb8(255, 0, 0));
      drawPixel(image, 4, 0, ColorRgb8(255, 0, 0));
      drawPixel(image, 0, 4, ColorRgb8(255, 0, 0));
      // Every pixel should still be black.
      expectSolidColor(image, ColorRgb8(0, 0, 0),
          reason: 'out-of-bounds draws should not modify any pixel');
    });

    test('drawPixel with alpha blend composites correctly on black background',
        () {
      // Drawing 50%-opaque white (128/255) on black → result ~= 128 per channel.
      final image = Image(width: 1, height: 1, numChannels: 4);
      drawPixel(image, 0, 0, ColorRgba8(255, 255, 255, 128));
      final p = image.getPixel(0, 0);
      // The blended red/green/blue should be between 120 and 136.
      expect(p.r, greaterThan(100), reason: 'blended red should be ~128');
      expect(p.r, lessThan(150), reason: 'blended red should be ~128');
    });
  });
}
