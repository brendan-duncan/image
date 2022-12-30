import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('separableConvolution', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;

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
    });
  });
}
