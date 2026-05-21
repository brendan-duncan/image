import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('smooth', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      smooth(i0, weight: 0.5);
      File('$testOutputPath/filter/smooth.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('smooth preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = smooth(src.clone(), weight: 0.5);
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('smooth on a solid-color image leaves it unchanged', () {
      final src = solidImage(32, 32, ColorRgb8(80, 160, 40));
      // The smooth kernel is a weighted average; uniform input → unchanged.
      testImageEquals(smooth(src.clone(), weight: 0.5), src);
    });

    test('smooth reduces variance of a checker image', () {
      final src = checkerImage(64, 64, cell: 4);
      final result = smooth(src.clone(), weight: 0.5);
      // Smoothing averages neighbouring pixels → lower variance.
      expect(imageVariance(result), lessThan(imageVariance(src)));
    });

    test('smooth returns src and mutates in place', () {
      final src = checkerImage(32, 32);
      final result = smooth(src, weight: 0.5);
      // The function documents that it returns src after mutating it.
      expect(identical(result, src), isTrue);
    });
  });
}
