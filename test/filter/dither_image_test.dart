import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('ditherImage', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;

      var id = ditherImage(i0, kernel: DitherKernel.atkinson);
      File('$testOutputPath/filter/dither_Atkinson.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0);
      File('$testOutputPath/filter/dither_FloydSteinberg.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.falseFloydSteinberg);
      File('$testOutputPath/filter/dither_FalseFloydSteinberg.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.stucki);
      File('$testOutputPath/filter/dither_Stucki.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.none);
      File('$testOutputPath/filter/dither_None.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));
    });
  });
}
