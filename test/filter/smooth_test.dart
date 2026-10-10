import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('smooth', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      smooth(i0, weight: 0.5);
      File('$testOutputPath/filter/smooth.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      // Each pixel is the average of its 8 neighbors and itself, with the
      // center weighted by 0.5 (edge pixels repeat the border).
      for (final p in i0) {
        final e = [0.0, 0.0, 0.0];
        for (var j = -1; j <= 1; ++j) {
          for (var i = -1; i <= 1; ++i) {
            final w = i == 0 && j == 0 ? 0.5 : 1.0;
            final o = orig.getPixel((p.x + i).clamp(0, orig.width - 1),
                (p.y + j).clamp(0, orig.height - 1));
            for (var c = 0; c < 3; ++c) {
              e[c] += w * o[c];
            }
          }
        }
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo(e[c] / 8.5, 1),
              reason: 'channel $c at ${p.x},${p.y}');
        }
      }
      expect(imageVariance(i0), lessThan(imageVariance(orig)));
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
      // Smoothing averages neighboring pixels → lower variance.
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
