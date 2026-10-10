import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// The Sobel gradient magnitude of the normalized luminance of [img] at
// x, y, clamping neighbors to the image edges.
double _sobelMagnitude(Image img, int x, int y) {
  num l(int dx, int dy) => img
      .getPixel(
          (x + dx).clamp(0, img.width - 1), (y + dy).clamp(0, img.height - 1))
      .luminanceNormalized;
  final h =
      -l(-1, -1) - 2 * l(0, -1) - l(1, -1) + l(-1, 1) + 2 * l(0, 1) + l(1, 1);
  final v =
      -l(-1, 1) - 2 * l(-1, 0) - l(-1, -1) + l(1, 1) + 2 * l(1, 0) + l(1, -1);
  return sqrt(h * h + v * v);
}

void main() {
  group('Filter', () {
    test('sobel', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      sobel(i0);
      File('$testOutputPath/filter/sobel.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      // Each pixel becomes the gray Sobel edge magnitude of the luminance.
      var edges = 0;
      var flat = 0;
      for (final p in i0) {
        final e = (_sobelMagnitude(orig, p.x, p.y) * 255).clamp(0, 255);
        expect(p.r, closeTo(e, 1), reason: 'r at ${p.x},${p.y}');
        expect(p.g, equals(p.r), reason: 'g at ${p.x},${p.y}');
        expect(p.b, equals(p.r), reason: 'b at ${p.x},${p.y}');
        if (p.r > 128) {
          edges++;
        } else if (p.r < 16) {
          flat++;
        }
      }
      expect(edges, greaterThan(100));
      expect(flat, greaterThan(100));

      // A vertical step responds only along the step.
      final step = solidImage(16, 8, ColorRgb8(50, 50, 50));
      for (final p in step) {
        if (p.x >= 8) {
          p.setRgb(200, 200, 200);
        }
      }
      sobel(step);
      for (final p in step) {
        if (p.x == 7 || p.x == 8) {
          // |v| = 4 * 150 / 255, clamped to 1.
          expect(p.r, equals(255), reason: 'edge at ${p.x},${p.y}');
        } else {
          expect(p.r, equals(0), reason: 'flat at ${p.x},${p.y}');
        }
      }
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
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
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
