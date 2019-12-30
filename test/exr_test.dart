import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('EXR', () {
    test('decoding', () {
      List<int> bytes = File('test/res/exr/grid.exr').readAsBytesSync();

      final dec = ExrDecoder();
      dec.startDecode(bytes);
      final img = dec.decodeFrame(0);

      final png = PngEncoder().encodeImage(img);
      File('.dart_tool/out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });
  });
}
