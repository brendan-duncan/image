import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('bulgeDistortion', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      bulgeDistortion(i0, interpolation: Interpolation.cubic);
      File('$testOutputPath/filter/bulgeDistortion.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));

      // Outside the default radius every pixel samples itself; inside it,
      // pixels are pulled from closer to the center.
      final cx = i0.width ~/ 2;
      final cy = i0.height ~/ 2;
      final rad = min(i0.width, i0.height) ~/ 2;
      var inside = 0;
      var changed = 0;
      for (final p in i0) {
        final dx = p.x - cx;
        final dy = p.y - cy;
        final o = orig.getPixel(p.x, p.y);
        if (dx * dx + dy * dy >= rad * rad) {
          expect(p, equals(o), reason: 'outside radius at ${p.x},${p.y}');
        } else {
          inside++;
          if (p != o) {
            changed++;
          }
        }
      }
      expect(changed, greaterThan(inside ~/ 2));
      // The center maps onto itself.
      expect(i0.getPixel(cx, cy), equals(orig.getPixel(cx, cy)));

      // On a horizontal ramp, a pixel inside the radius takes its value from
      // a column between itself and the center (magnification).
      final ramp = horizontalGradient(64, 64);
      final bulged = bulgeDistortion(ramp.clone());
      var moved = 0;
      for (final p in bulged) {
        final dx = p.x - 32;
        final dy = p.y - 32;
        final v = ramp.getPixel(p.x, p.y).r;
        if (dx * dx + dy * dy >= 32 * 32) {
          expect(p.r, equals(v), reason: 'outside radius at ${p.x},${p.y}');
          continue;
        }
        final c = ramp.getPixel(32, p.y).r;
        expect(p.r, inInclusiveRange(min(c, v), max(c, v)),
            reason: 'inside radius at ${p.x},${p.y}');
        if (p.r != v) {
          moved++;
        }
      }
      expect(moved, greaterThan(1000));
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
