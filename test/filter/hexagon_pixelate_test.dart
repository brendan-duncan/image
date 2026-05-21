import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('hexagonPixelate', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      hexagonPixelate(i0, centerX: 50);
      File('$testOutputPath/filter/hexagonPixelate.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('hexagonPixelate preserves dimensions', () {
      final src = solidImage(40, 30, ColorRgb8(100, 150, 200));
      final result = hexagonPixelate(src.clone());
      // Hexagon pixelation must not resize the image.
      expect(result.width, equals(40));
      expect(result.height, equals(30));
    });

    test('hexagonPixelate returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(80, 160, 240));
      final result = hexagonPixelate(src);
      expect(identical(result, src), isTrue);
    });

    test('hexagonPixelate on a solid-color image yields solid color', () {
      // Hexagon pixelation only remaps pixels; a uniform image stays uniform.
      final color = ColorRgb8(60, 120, 180);
      final src = solidImage(32, 32, color);
      hexagonPixelate(src);
      expectSolidColor(src, color);
    });

    test('hexagonPixelate with amount 0 leaves image unchanged', () {
      // amount==0 means mx==0, so mix(p, newColor, 0)==p.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      hexagonPixelate(src, amount: 0);
      testImageEquals(src, orig);
    });
  });
}
