import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('gaussianBlur', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      gaussianBlur(i0, radius: 10);
      File('$testOutputPath/filter/gaussianBlur.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('gaussianBlur preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = gaussianBlur(src.clone(), radius: 4);
      // dimensions must be unchanged after blur
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('gaussianBlur with radius 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // radius <= 0 is a no-op per source
      testImageEquals(gaussianBlur(src.clone(), radius: 0), src);
    });

    test('gaussianBlur on a solid-color image leaves it unchanged', () {
      final src = solidImage(32, 32, ColorRgb8(100, 150, 200));
      // A normalised Gaussian kernel on uniform input is a weighted average of
      // identical values.  Two-pass floating-point accumulation may introduce
      // up to ±2 LSB rounding error.
      expectImagesClose(gaussianBlur(src.clone(), radius: 5), src,
          tolerance: 2);
    });

    test('gaussianBlur reduces variance of a non-uniform image', () {
      final src = checkerImage(64, 64, cell: 4);
      final blurred = gaussianBlur(src.clone(), radius: 6);
      // blurring smooths out high-frequency content → lower variance
      expect(imageVariance(blurred), lessThan(imageVariance(src)));
    });
  });
}
