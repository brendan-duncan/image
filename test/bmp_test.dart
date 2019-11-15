import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = Directory('test/res/bmp');
  if (!dir.existsSync()) {
    return;
  }
  var files = dir.listSync();

  group('BMP', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.bmp')) {
        continue;
      }

      String name = f.path.split(RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        Image image = BmpDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode TGA Image: $name.');
        }

        List<int> png = PngEncoder().encodeImage(image);
        File('.dart_tool/out/bmp/${name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }
  });
}
