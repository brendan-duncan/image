import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void ExrTest() {
  group('EXR', () {
    test('decoding', () {
      final bytes = File('test/data/exr/grid.exr').readAsBytesSync();

      final dec = ExrDecoder();
      dec.startDecode(bytes);
      final img = dec.decodeFrame(0)!;

      final png = PngEncoder().encodeImage(img);
      File('$tmpPath/out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });
  });
}
