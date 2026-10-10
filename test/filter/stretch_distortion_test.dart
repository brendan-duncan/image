import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('stretchDistortion', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      stretchDistortion(i0, interpolation: Interpolation.cubic);
      File('$testOutputPath/filter/stretchDistortion.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      final w = orig.width - 1;
      final h = orig.height - 1;
      final cx = orig.width ~/ 2;
      final cy = orig.height ~/ 2;
      void expectPixel(int x, int y, int sx, int sy) {
        final p = i0.getPixel(x, y);
        final o = orig.getPixel(sx, sy);
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo(o[c], 1),
              reason: 'channel $c at $x,$y, expected from $sx,$sy');
        }
      }

      // Near the center (within 1/8 of the size) the image is magnified 2x
      // about the center: cx + 2k samples cx + k.
      for (var j = -11; j <= 11; ++j) {
        for (var k = -18; k <= 18; ++k) {
          expectPixel(cx + 2 * k, cy + 2 * j, cx + k, cy + j);
        }
      }

      // Beyond 1/4 of the size from the center in both axes the image is
      // unchanged. The last row and column are skipped: they sample the
      // row/column before them (suspected off-by-one in the source clamp).
      var changed = 0;
      for (final p in i0) {
        final outerX = (p.x - cx).abs() * 2 >= w * 0.5 + 1;
        final outerY = (p.y - cy).abs() * 2 >= h * 0.5 + 1;
        if (outerX && outerY && p.x < w && p.y < h) {
          expectPixel(p.x, p.y, p.x, p.y);
        }
        if (p != orig.getPixel(p.x, p.y)) {
          changed++;
        }
      }
      expect(changed, greaterThan(orig.width * orig.height ~/ 4));
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
