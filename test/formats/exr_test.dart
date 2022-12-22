import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void exrTest() {
  group('exr', () {
    test('decoding', () {
      final bytes = File('test/_data/exr/grid.exr').readAsBytesSync();

      final dec = ExrDecoder()
      ..startDecode(bytes);
      final img = dec.decodeFrame(0)!;

      final png = PngEncoder().encode(img);
      File('$testOutputPath/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });
  });
}
