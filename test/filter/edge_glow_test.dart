import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('edgeGlow', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      edgeGlow(i0);
      File('$testOutputPath/filter/edgeGlow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
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
