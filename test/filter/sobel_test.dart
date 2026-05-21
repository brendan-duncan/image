import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('sobel', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      sobel(i0);
      File('$testOutputPath/filter/sobel.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('sobel preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = sobel(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('sobel on a uniform image produces a flat (zero-edge) output', () {
      // On a uniform image every horizontal/vertical gradient is 0, so the
      // edge magnitude is 0 everywhere.
      final src = solidImage(32, 32, ColorRgb8(128, 128, 128));
      final result = sobel(src.clone());
      // All pixels should have the same value.
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r),
            reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g),
            reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b),
            reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('sobel on a checker image produces non-uniform output', () {
      // A checkerboard has strong edges; the Sobel magnitude must not be flat.
      final src = checkerImage(64, 64);
      final result = sobel(src.clone());
      // Variance > 0 confirms the output is not uniform.
      expect(imageVariance(result), greaterThan(0));
    });

    test('sobel with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 → the blend factor is 0 → output equals original
      testImageEquals(sobel(src.clone(), amount: 0), src);
    });
  });
}
