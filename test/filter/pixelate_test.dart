import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('pixelate', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final i1 = i0.clone();
      pixelate(i0, size: 10);
      File('$testOutputPath/filter/pixelate_upperLeft.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      pixelate(i1, size: 10, mode: PixelateMode.average);
      File('$testOutputPath/filter/pixelate_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('pixelate preserves dimensions', () {
      final src = solidImage(40, 30, ColorRgb8(100, 150, 200));
      final result = pixelate(src.clone(), size: 8);
      // Pixelation must not resize the image.
      expect(result.width, equals(40));
      expect(result.height, equals(30));
    });

    test('pixelate returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 100, 100));
      final result = pixelate(src, size: 4);
      expect(identical(result, src), isTrue);
    });

    test('pixelate upperLeft: pixels in the same block are equal', () {
      // With upperLeft mode every pixel in a block gets the top-left value.
      // Use a block size of 4 and an image that is an exact multiple.
      const blockSize = 4;
      const w = 32;
      const h = 32;
      final src = horizontalGradient(w, h);
      pixelate(src, size: blockSize);
      for (var by = 0; by < h; by += blockSize) {
        for (var bx = 0; bx < w; bx += blockSize) {
          // Sample two pixels inside the same block.
          final p0 = src.getPixel(bx, by);
          final p1 = src.getPixel(bx + 1, by + 1);
          expect(p1.r, equals(p0.r), reason: 'block at ($bx,$by): r mismatch');
          expect(p1.g, equals(p0.g), reason: 'block at ($bx,$by): g mismatch');
          expect(p1.b, equals(p0.b), reason: 'block at ($bx,$by): b mismatch');
        }
      }
    });

    test('pixelate average: same-block pixels within 1 of each other', () {
      // With average mode every pixel in a block gets mix(orig, avg, 1).
      // Integer rounding means adjacent pixels may differ by at most 1.
      const blockSize = 4;
      const w = 32;
      const h = 32;
      final src = horizontalGradient(w, h);
      pixelate(src, size: blockSize, mode: PixelateMode.average);
      for (var by = 0; by < h; by += blockSize) {
        for (var bx = 0; bx < w; bx += blockSize) {
          final p0 = src.getPixel(bx, by);
          final p1 = src.getPixel(bx + 2, by + 2);
          expect((p1.r - p0.r).abs(), lessThanOrEqualTo(1),
              reason: 'block at ($bx,$by): r differs by more than 1');
          expect((p1.g - p0.g).abs(), lessThanOrEqualTo(1),
              reason: 'block at ($bx,$by): g differs by more than 1');
          expect((p1.b - p0.b).abs(), lessThanOrEqualTo(1),
              reason: 'block at ($bx,$by): b differs by more than 1');
        }
      }
    });

    test('pixelate size 1 is a no-op', () {
      // The source documents that size <= 1 returns src unchanged.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      pixelate(src, size: 1);
      testImageEquals(src, orig);
    });
  });
}
