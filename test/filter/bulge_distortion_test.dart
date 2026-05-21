import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('bulgeDistortion', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      bulgeDistortion(i0, interpolation: Interpolation.cubic);
      File('$testOutputPath/filter/bulgeDistortion.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('bulgeDistortion preserves dimensions', () {
      final src = solidImage(32, 24, ColorRgb8(100, 150, 200));
      final result = bulgeDistortion(src.clone());
      // Distortion must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(24));
    });

    test('bulgeDistortion on a solid-color image yields solid color', () {
      // A bulge only remaps pixel positions; sampling from a uniform image
      // always returns the same color.
      final color = ColorRgb8(80, 160, 240);
      final src = solidImage(32, 32, color);
      final result = bulgeDistortion(src);
      expectSolidColor(result, color);
    });

    test('bulgeDistortion returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(10, 20, 30));
      final result = bulgeDistortion(src);
      // The function must mutate in place and return the same object.
      expect(identical(result, src), isTrue);
    });

    test('bulgeDistortion with zero-mask leaves image unchanged', () {
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      final zeroMask = solidImage(32, 32, ColorRgb8(0, 0, 0));
      bulgeDistortion(src, mask: zeroMask);
      // A fully-black mask means msk==0 and mix(p, p2, 0)==p, so no change.
      testImageEquals(src, orig);
    });
  });
}
