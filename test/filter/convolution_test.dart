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
  });
}
