import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyCropCircle', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = PngDecoder().decode(bytes)!.convert(numChannels: 4);
      final i0_1 = copyCropCircle(i0);
      expect(i0_1.width, equals(186));
      expect(i0_1.height, equals(186));
      expect(i0_1.format, equals(i0.format));
      File('$testOutputPath/transform/copyCropCircle.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_1));
    });

    // Result dimensions are radius*2 × radius*2.
    test('result dimensions equal diameter of the circle', () {
      final src = solidImage(64, 64, ColorRgb8(255, 0, 0),
          numChannels: 4);
      const r = 20;
      final result = copyCropCircle(src, radius: r);
      expect(result.width, equals(r * 2));
      expect(result.height, equals(r * 2));
    });

    // Default radius uses min(width,height)/2.
    test('default radius uses half the shorter side', () {
      final src = solidImage(40, 30, ColorRgb8(0, 255, 0), numChannels: 4);
      final result = copyCropCircle(src);
      // min(40,30)/2 = 15  →  diameter = 30
      expect(result.width, equals(30));
      expect(result.height, equals(30));
    });

    // copyCropCircle does not mutate the source image.
    test('copyCropCircle does not mutate source', () {
      final src = solidImage(32, 32, ColorRgb8(100, 150, 200),
          numChannels: 4);
      final orig = src.clone();
      copyCropCircle(src, radius: 12);
      testImageEquals(src, orig);
    });

    // Corners outside the inscribed circle must be transparent (alpha == 0).
    test('corner pixels outside the circle are transparent', () {
      final src = solidImage(32, 32, ColorRgb8(255, 100, 50),
          numChannels: 4);
      final result = copyCropCircle(src, radius: 16,
          centerX: 16, centerY: 16);
      // The very corner (0,0) is outside a circle of radius 16 centred at
      // (16,16) since distance = 16*sqrt(2) ≈ 22.6 > 16.
      final corner = result.getPixel(0, 0);
      expect(corner.a, equals(0),
          reason: 'corner pixel should be transparent');
    });

    // A pixel at the exact centre of the circle must not be cleared.
    test('centre pixel is not transparent', () {
      final src = solidImage(32, 32, ColorRgb8(200, 100, 50),
          numChannels: 4);
      final result = copyCropCircle(src, radius: 16,
          centerX: 16, centerY: 16);
      // Centre of the output square = (15, 15) (diameter=32, so index 15).
      final centre = result.getPixel(15, 15);
      expect(centre.a, greaterThan(0),
          reason: 'centre pixel must not be transparent');
    });
  });
}
