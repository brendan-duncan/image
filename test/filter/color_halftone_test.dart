import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('colorHalftone', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      colorHalftone(i0);
      File('$testOutputPath/filter/colorHalftone.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('colorHalftone preserves dimensions', () {
      final src = solidImage(32, 32, ColorRgb8(200, 100, 50));
      final result = colorHalftone(src.clone());
      // The halftone stylization must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
    });

    test('colorHalftone returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 150, 200));
      final result = colorHalftone(src);
      expect(identical(result, src), isTrue);
    });

    test('colorHalftone with amount 0 leaves image unchanged', () {
      // amount==0 means mx==0, so mix(p, newColor, 0)==p.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      colorHalftone(src, amount: 0);
      testImageEquals(src, orig);
    });

    test('colorHalftone output values stay within channel range', () {
      // Channel values must remain within [0, maxChannelValue].
      final src = quadrantImage(32, 32);
      colorHalftone(src);
      for (final p in src) {
        expect(p.r, greaterThanOrEqualTo(0));
        expect(p.r, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.g, greaterThanOrEqualTo(0));
        expect(p.g, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.b, greaterThanOrEqualTo(0));
        expect(p.b, lessThanOrEqualTo(p.maxChannelValue));
      }
    });
  });
}
