import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('stretchDistortion', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      stretchDistortion(i0, interpolation: Interpolation.cubic);
      File('$testOutputPath/filter/stretchDistortion.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('stretchDistortion preserves dimensions', () {
      final src = solidImage(40, 30, ColorRgb8(100, 150, 200));
      final result = stretchDistortion(src.clone());
      // Distortion must not resize the image.
      expect(result.width, equals(40));
      expect(result.height, equals(30));
    });

    test('stretchDistortion on a solid-color image yields solid color', () {
      // Stretch only remaps pixel positions; sampling from a uniform image
      // always returns the same color regardless of the warp mapping.
      final color = ColorRgb8(60, 120, 180);
      final src = solidImage(32, 32, color);
      final result = stretchDistortion(src);
      expectSolidColor(result, color);
    });

    test('stretchDistortion returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(10, 20, 30));
      final result = stretchDistortion(src);
      // The function must mutate in place and return the same object.
      expect(identical(result, src), isTrue);
    });

    test('stretchDistortion with zero-mask leaves image unchanged', () {
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      final zeroMask = solidImage(32, 32, ColorRgb8(0, 0, 0));
      stretchDistortion(src, mask: zeroMask);
      // A fully-black mask means mix(p, p2, 0)==p, so no change.
      testImageEquals(src, orig);
    });
  });
}
