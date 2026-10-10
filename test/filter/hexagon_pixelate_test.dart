import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('hexagonPixelate', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      hexagonPixelate(i0, centerX: 50);
      File('$testOutputPath/filter/hexagonPixelate.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));

      // Every pixel takes the color of a source pixel (its cell's center),
      // so no new colors appear, far fewer distinct colors remain, and
      // neighboring pixels mostly share a color.
      int key(Pixel p) =>
          (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
      final srcColors = {for (final p in orig) key(p)};
      final dstColors = <int>{};
      var same = 0;
      for (final p in i0) {
        expect(srcColors.contains(key(p)), isTrue,
            reason: 'new color at ${p.x},${p.y}');
        dstColors.add(key(p));
        if (p.x > 0 && i0.getPixel(p.x - 1, p.y) == p) {
          same++;
        }
      }
      expect(dstColors.length, lessThan(srcColors.length / 4));
      expect(same, greaterThan((i0.width - 1) * i0.height * 0.7));

      // On a horizontal ramp, each pixel's value comes from a column inside
      // its own cell (size 5).
      final ramp = horizontalGradient(64, 32);
      final pixelated = hexagonPixelate(ramp.clone());
      var changed = 0;
      for (final p in pixelated) {
        final v = ramp.getPixel(p.x, p.y).r;
        final col = (p.r * 63 / 255).round();
        expect((col - p.x).abs(), lessThanOrEqualTo(4),
            reason: 'at ${p.x},${p.y}');
        if (p.r != v) {
          changed++;
        }
      }
      expect(changed, greaterThan(64 * 32 / 2));
    });

    test('hexagonPixelate preserves dimensions', () {
      final src = solidImage(40, 30, ColorRgb8(100, 150, 200));
      final result = hexagonPixelate(src.clone());
      // Hexagon pixelation must not resize the image.
      expect(result.width, equals(40));
      expect(result.height, equals(30));
    });

    test('hexagonPixelate returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(80, 160, 240));
      final result = hexagonPixelate(src);
      expect(identical(result, src), isTrue);
    });

    test('hexagonPixelate on a solid-color image yields solid color', () {
      // Hexagon pixelation only remaps pixels; a uniform image stays uniform.
      final color = ColorRgb8(60, 120, 180);
      final src = solidImage(32, 32, color);
      hexagonPixelate(src);
      expectSolidColor(src, color);
    });

    test('hexagonPixelate with amount 0 leaves image unchanged', () {
      // amount==0 means mx==0, so mix(p, newColor, 0)==p.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      hexagonPixelate(src, amount: 0);
      testImageEquals(src, orig);
    });
  });
}
