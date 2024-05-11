import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('quantize', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();

      final i0 = decodePng(bytes)!;
      final q0 =
          quantize(i0, numberOfColors: 32, method: QuantizeMethod.octree);
      File('$testOutputPath/filter/quantize_octree.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q0));

      final i0_ = decodePng(bytes)!;
      final q0_ = quantize(i0_,
          numberOfColors: 32,
          method: QuantizeMethod.octree,
          dither: DitherKernel.floydSteinberg);
      File('$testOutputPath/filter/quantize_octree_dither.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q0_));

      final i1 = decodePng(bytes)!;
      final q1 = quantize(i1, numberOfColors: 32);
      File('$testOutputPath/filter/quantize_neural.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q1));

      final i2 = decodePng(bytes)!;
      final q2 = quantize(grayscale(i2),
          numberOfColors: 2, dither: DitherKernel.floydSteinberg);
      File('$testOutputPath/filter/quantize_neural_dither.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q2));

      final i3 = decodePng(File('test/_data/png/david.png').readAsBytesSync())!;
      final q3 = quantize(i3,
          method: QuantizeMethod.binary, dither: DitherKernel.floydSteinberg);
      File('$testOutputPath/filter/quantize_binary.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q3));
    });
  });
}
