import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = Directory('res/tga');
  if (!dir.existsSync()) {
    return;
  }
  List files = dir.listSync();

  group('TGA', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.tga')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = TgaDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode TGA Image: $name.');
        }

        List<int> png = PngEncoder().encodeImage(image);
        new File('out/tga/${name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }

    test('decode/encode', () {
      List<int> bytes = File('res/tga/globe.tga').readAsBytesSync();

      // Decode the image from file.
      Image image = TgaDecoder().decodeImage(bytes);
      expect(image.width, equals(128));
      expect(image.height, equals(128));

      // Encode the image as a tga
      List<int> tga = TgaEncoder().encodeImage(image);

      new File('out/globe.tga')
        ..createSync(recursive: true)
        ..writeAsBytesSync(tga);

      // Decode the encoded image, make sure it's the same as the original.
      Image image2 = TgaDecoder().decodeImage(tga);
      expect(image2.width, equals(128));
      expect(image2.height, equals(128));
    });
  });
}
