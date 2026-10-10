import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Build a normalized Gaussian separable kernel with the given [radius].
SeparableKernel _gaussianKernel(int radius) {
  final kernel = SeparableKernel(radius);
  final num sigma = radius * (2.0 / 3.0);
  final num s = 2.0 * sigma * sigma;
  num sum = 0.0;
  for (var x = -radius; x <= radius; ++x) {
    final num c = exp(-(x * x) / s);
    sum += c;
    kernel[x + radius] = c;
  }
  kernel.scaleCoefficients(1.0 / sum);
  return kernel;
}

/// Build a separable identity kernel (single center coefficient = 1).
SeparableKernel _identityKernel() {
  final kernel = SeparableKernel(1); // size 1 → 3 coefficients
  kernel[0] = 0;
  kernel[1] = 1; // center weight
  kernel[2] = 0;
  return kernel;
}

void main() {
  group('Filter', () {
    test('separableConvolution', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();

      const radius = 5;
      final kernel = SeparableKernel(radius);
      // Compute coefficients
      const num sigma = radius * (2.0 / 3.0);
      const num s = 2.0 * sigma * sigma;

      num sum = 0.0;
      for (var x = -radius; x <= radius; ++x) {
        final num c = exp(-(x * x) / s);
        sum += c;
        kernel[x + radius] = c;
      }
      // Normalize the coefficients
      kernel.scaleCoefficients(1.0 / sum);

      separableConvolution(i0, kernel: kernel);

      File('$testOutputPath/filter/separableConvolution.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      // Away from the edges each pixel is the 2D weighted sum of its
      // neighbors, with weights kernel[i] * kernel[j].
      for (var y = radius; y < orig.height - radius; ++y) {
        for (var x = radius; x < orig.width - radius; ++x) {
          final e = [0.0, 0.0, 0.0];
          for (var j = -radius; j <= radius; ++j) {
            for (var i = -radius; i <= radius; ++i) {
              final w = kernel[i + radius] * kernel[j + radius];
              final o = orig.getPixel(x + i, y + j);
              for (var c = 0; c < 3; ++c) {
                e[c] += w * o[c];
              }
            }
          }
          final p = i0.getPixel(x, y);
          for (var c = 0; c < 3; ++c) {
            // Each of the two passes truncates, losing less than 1.
            expect(p[c], inInclusiveRange(e[c] - 2.001, e[c] + 0.001),
                reason: 'channel $c at $x,$y');
          }
        }
      }
      // Blurring lowers the variance but roughly keeps the mean.
      expect(imageVariance(i0), lessThan(imageVariance(orig)));
      expect(imageMean(i0), closeTo(imageMean(orig), 2));
    });

    test('separableConvolution preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result =
          separableConvolution(src.clone(), kernel: _gaussianKernel(4));
      // dimensions must be unchanged
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('separableConvolution identity kernel leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // An identity kernel (0, 1, 0) applied in both axes is a no-op.
      testImageEquals(
        separableConvolution(src.clone(), kernel: _identityKernel()),
        src,
      );
    });

    test('separableConvolution Gaussian on solid image leaves it unchanged',
        () {
      final src = solidImage(32, 32, ColorRgb8(60, 120, 180));
      // A normalized kernel on uniform input is a weighted average of the
      // same constant value.  Two-pass floating-point accumulation may
      // introduce up to ±2 LSB rounding error.
      expectImagesClose(
        separableConvolution(src.clone(), kernel: _gaussianKernel(5)),
        src,
        tolerance: 2,
      );
    });

    test('separableConvolution Gaussian reduces variance of a checker image',
        () {
      final src = checkerImage(64, 64, cell: 4);
      final blurred =
          separableConvolution(src.clone(), kernel: _gaussianKernel(6));
      // Blurring smooths high-frequency content → lower variance.
      expect(imageVariance(blurred), lessThan(imageVariance(src)));
    });
  });
}
