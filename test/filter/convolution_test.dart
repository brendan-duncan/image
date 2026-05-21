import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('convolution', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      // sharpening kernel
      /*const filter = [ 0, -1,  0,
                      -1,  5, -1,
                       0, -1,  0 ];*/
      // laplacian kernel
      const filter = [0, 1, 0, 1, -4, 1, 0, 1, 0];
      convolution(i0, filter: filter, div: 1, offset: 0);
      File('$testOutputPath/filter/convolution.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('convolution preserves dimensions', () {
      final src = checkerImage(32, 24);
      const filter = [0, 1, 0, 1, -4, 1, 0, 1, 0];
      final result =
          convolution(src.clone(), filter: filter, div: 1, offset: 0);
      // dimensions must not change
      expect(result.width, equals(32));
      expect(result.height, equals(24));
    });

    test('convolution identity kernel leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // The identity 3x3 kernel: only the centre coefficient is 1.
      // div=1, offset=0 → output pixel == input pixel.
      const identity = [0, 0, 0, 0, 1, 0, 0, 0, 0];
      testImageEquals(
        convolution(src.clone(), filter: identity, div: 1, offset: 0),
        src,
      );
    });

    test('convolution box-blur kernel on a solid image leaves it unchanged',
        () {
      final src = solidImage(32, 32, ColorRgb8(80, 120, 200));
      // Uniform box-blur: all 9 weights = 1, div = 9.
      // Every neighbourhood has the same constant values, so output == input.
      const box = [1, 1, 1, 1, 1, 1, 1, 1, 1];
      testImageEquals(
        convolution(src.clone(), filter: box, div: 9, offset: 0),
        src,
      );
    });

    test('convolution with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      const filter = [0, 1, 0, 1, -4, 1, 0, 1, 0];
      // amount=0 → the mix is 0 → output == original
      testImageEquals(
        convolution(src.clone(), filter: filter, div: 1, offset: 0, amount: 0),
        src,
      );
    });
  });
}
