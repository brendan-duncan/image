import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('edgeGlow', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      edgeGlow(i0);
      File('$testOutputPath/filter/edgeGlow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));

      // Each channel is its Sobel gradient magnitude scaled by twice the
      // pixel's own value, so flat areas go black and edges glow.
      num at(int x, int y, int c) =>
          orig.getPixel(
              x.clamp(0, orig.width - 1), y.clamp(0, orig.height - 1))[c] /
          255;
      var flat = 0;
      for (final p in i0) {
        final x = p.x;
        final y = p.y;
        for (var c = 0; c < 3; ++c) {
          final gx = at(x - 1, y - 1, c) +
              2 * at(x, y - 1, c) +
              at(x + 1, y - 1, c) -
              at(x - 1, y + 1, c) -
              2 * at(x, y + 1, c) -
              at(x + 1, y + 1, c);
          final gy = at(x - 1, y - 1, c) -
              at(x + 1, y - 1, c) +
              2 * at(x - 1, y, c) -
              2 * at(x + 1, y, c) +
              at(x - 1, y + 1, c) -
              at(x + 1, y + 1, c);
          final v = sqrt(gx * gx + gy * gy) * 2 * at(x, y, c) * 255;
          expect(p[c], closeTo(v.clamp(0, 255), 1),
              reason: 'channel $c at $x,$y');
          if (gx == 0 && gy == 0) {
            expect(p[c], equals(0), reason: 'flat channel $c at $x,$y');
            flat++;
          }
        }
      }
      expect(flat, greaterThan(0));
      expect(imageMean(i0), lessThan(imageMean(orig)));

      // At a vertical edge between black and gray, only the first gray
      // column glows (black pixels stay black, being scaled by 0).
      final edge = Image(width: 16, height: 8);
      for (final p in edge) {
        final v = p.x < 8 ? 0 : 200;
        p.setRgb(v, v, v);
      }
      edgeGlow(edge);
      for (final p in edge) {
        expect(p.r, equals(p.x == 8 ? 255 : 0), reason: 'at ${p.x},${p.y}');
      }
    });

    test('edgeGlow preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = edgeGlow(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('edgeGlow on a uniform image produces a flat output', () {
      // On a uniform image every Sobel-style gradient is 0, so rrR/G/B = 0
      // and r/g/b = 0 * 2 * pixel_normalized * maxChannelValue = 0.
      // The output is therefore uniform (all zeros).
      final src = solidImage(32, 32, ColorRgb8(120, 120, 120));
      final result = edgeGlow(src.clone());
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('edgeGlow on a checker image produces non-uniform output', () {
      // A checkerboard has strong edges; edge glow must produce variation.
      final src = checkerImage(64, 64);
      final result = edgeGlow(src.clone());
      // Variance > 0 confirms the output is not uniform.
      expect(imageVariance(result), greaterThan(0));
    });

    test('edgeGlow with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 → early return, no mutation
      testImageEquals(edgeGlow(src.clone(), amount: 0), src);
    });
  });
}
