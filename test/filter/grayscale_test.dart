import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('grayscale', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      grayscale(i0);
      File('$testOutputPath/filter/grayscale.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // A grayscale image has equal r, g and b in every pixel.
      for (final p in i0) {
        expect(p.r, equals(p.g), reason: 'r==g at ${p.x},${p.y}');
        expect(p.g, equals(p.b), reason: 'g==b at ${p.x},${p.y}');
      }
    });

    test('grayscale is idempotent on an already-neutral image', () {
      final gray = solidImage(16, 16, ColorRgb8(123, 123, 123));
      testImageEquals(grayscale(gray.clone()), gray);
    });

    test('grayscale collapses a color to its luminance', () {
      for (final color in [
        ColorRgb8(255, 0, 0),
        ColorRgb8(0, 255, 0),
        ColorRgb8(0, 0, 255),
        ColorRgb8(200, 100, 50),
      ]) {
        final l = getLuminanceRgb(color.r, color.g, color.b);
        final result = grayscale(solidImage(8, 8, color));
        final p = result.getPixel(0, 0);
        expect(p.r, equals(p.g));
        expect(p.g, equals(p.b));
        expect((p.r - l).abs(), lessThanOrEqualTo(1),
            reason: 'grayscale of $color should be near luminance $l');
      }
    });

    test('grayscale with amount 0 leaves the image unchanged', () {
      final src = quadrantImage(16, 16);
      testImageEquals(grayscale(src.clone(), amount: 0), src);
    });
  });
}
