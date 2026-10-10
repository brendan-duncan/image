import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('chromaticAberration', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      chromaticAberration(i0);
      File('$testOutputPath/filter/chromaticAberration.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      // With the default shift of 5, red is read from 5 pixels to the right,
      // blue from 5 pixels to the left (clamped at the edges), and green is
      // untouched.
      final w = i0.width - 1;
      var changed = 0;
      for (final p in i0) {
        final right = orig.getPixel((p.x + 5).clamp(0, w), p.y);
        final left = orig.getPixel((p.x - 5).clamp(0, w), p.y);
        final o = orig.getPixel(p.x, p.y);
        final at = 'at ${p.x},${p.y}';
        expect(p.r, equals(right.r), reason: 'r $at');
        expect(p.g, equals(o.g), reason: 'g $at');
        expect(p.b, equals(left.b), reason: 'b $at');
        if (p.r != o.r || p.b != o.b) {
          changed++;
        }
      }
      expect(changed, greaterThan(i0.width * i0.height ~/ 2));
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
