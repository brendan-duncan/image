import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void quantizeTest() {
  test('quantize', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();

    final i0 = PngDecoder().decodeImage(bytes)!;
    quantize(i0, numberOfColors: 32, method: QuantizeMethod.octree);
    File('$tmpPath/out/filter/quantize_octree.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));

    final i1 = PngDecoder().decodeImage(bytes)!;
    quantize(i1, numberOfColors: 32);
    File('$tmpPath/out/filter/quantize_neural.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i1));
  });
}
