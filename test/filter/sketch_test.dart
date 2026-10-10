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
    test('sketch', () async {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final img = decodePng(bytes)!;
      final i0 = img.clone();
      sketch(i0);
      File('$testOutputPath/filter/sketch.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(img.width));
      expect(i0.height, equals(img.height));
      expect(i0.numChannels, equals(img.numChannels));
      // Each pixel is darkened by 1 - the Sobel edge magnitude, so flat areas
      // keep their color and edges turn dark.
      var darkened = 0;
      for (final p in i0) {
        final o = img.getPixel(p.x, p.y);
        final mag = 1 - _sobelMagnitude(img, p.x, p.y);
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo((o[c] * mag).clamp(0, 255), 1),
              reason: 'channel $c at ${p.x},${p.y}');
          expect(p[c], lessThanOrEqualTo(o[c]));
        }
        if (o.r - p.r > 64) {
          darkened++;
        }
      }
      expect(darkened, greaterThan(100));

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: img.width ~/ 2,
          y: img.height ~/ 2,
          radius: 80,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 20);

      final cmd = Command()
        ..image(img)
        ..copy()
        ..sketch(mask: mask)
        ..writeToFile('$testOutputPath/filter/sketch_mask.png');
      await cmd.execute();

      // Sketched inside the (blurred) circle, unchanged outside it.
      final masked = cmd.outputImage!;
      final cx = img.width ~/ 2;
      final cy = img.height ~/ 2;
      for (final p in masked) {
        final d = sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
        if (d < 55) {
          for (var c = 0; c < 3; ++c) {
            expect(p[c], closeTo(i0.getPixel(p.x, p.y)[c], 2),
                reason: 'channel $c at ${p.x},${p.y}');
          }
        } else if (d > 105) {
          expect(p, equals(img.getPixel(p.x, p.y)),
              reason: 'pixel ${p.x},${p.y}');
        }
      }
    });

    test('sketch preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = sketch(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('sketch on a uniform black image produces uniform output', () {
      // On a uniform image all gradients are 0 → mag = 1 - 0 = 1 → each
      // channel is multiplied by 1 → output equals input.
      final src = solidImage(32, 32, ColorRgb8(0, 0, 0));
      final result = sketch(src.clone());
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('sketch on a checker image produces non-uniform output', () {
      // A checkerboard has strong edges; the sketch output must not be flat.
      final src = checkerImage(64, 64);
      final result = sketch(src.clone());
      // Variance > 0 confirms the output is not uniform.
      expect(imageVariance(result), greaterThan(0));
    });

    test('sketch with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 → blend factor is 0 → output equals original
      testImageEquals(sketch(src.clone(), amount: 0), src);
    });
  });
}
