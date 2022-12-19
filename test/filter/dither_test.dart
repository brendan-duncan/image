import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void DitherTest() {
  test('dither', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;

    var id = ditherImage(i0);
    File('$tmpPath/out/filter/dither_FloydSteinberg.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(id));

    id = ditherImage(i0, kernel: DitherKernel.atkinson);
    File('$tmpPath/out/filter/dither_Atkinson.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(id));

    id = ditherImage(i0, kernel: DitherKernel.falseFloydSteinberg);
    File('$tmpPath/out/filter/dither_FalseFloydSteinberg.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(id));

    id = ditherImage(i0, kernel: DitherKernel.stucki);
    File('$tmpPath/out/filter/dither_Stucki.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(id));

    id = ditherImage(i0, kernel: DitherKernel.none);
    File('$tmpPath/out/filter/dither_None.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(id));
  });
}