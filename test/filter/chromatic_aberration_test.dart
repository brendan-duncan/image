import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('chromaticAberration', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      chromaticAberration(i0);
      File('$testOutputPath/filter/chromaticAberration.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('chromaticAberration preserves dimensions', () {
      final src = solidImage(40, 30, ColorRgb8(128, 128, 128));
      final result = chromaticAberration(src.clone());
      // Channel shift must not resize the image.
      expect(result.width, equals(40));
      expect(result.height, equals(30));
    });

    test('chromaticAberration returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 100, 100));
      final result = chromaticAberration(src);
      expect(identical(result, src), isTrue);
    });

    test('chromaticAberration on a uniform-gray image is a no-op', () {
      // The filter shifts red channel right and blue channel left.
      // When every pixel is identical (r==g==b everywhere) the shifted
      // neighbors have the same value, so the result is unchanged.
      final gray = solidImage(32, 16, ColorRgb8(120, 120, 120));
      final orig = gray.clone();
      chromaticAberration(gray, shift: 4);
      testImageEquals(gray, orig);
    });

    test('chromaticAberration with zero-mask leaves image unchanged', () {
      final src = horizontalGradient(32, 16);
      final orig = src.clone();
      final zeroMask = solidImage(32, 16, ColorRgb8(0, 0, 0));
      chromaticAberration(src, mask: zeroMask);
      // msk==0 means mix(p, shifted, 0)==p — original unchanged.
      testImageEquals(src, orig);
    });
  });
}
