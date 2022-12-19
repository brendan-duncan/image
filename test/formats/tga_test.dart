import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void tgaTest() {
  final dir = Directory('test/_data/tga');
  if (!dir.existsSync()) {
    return;
  }
  final files = dir.listSync();

  group('tga', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.tga')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final bytes = f.readAsBytesSync();
        final image = TgaDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode TGA Image: $name.');
        }

        //final png = PngEncoder().encodeImage(image);
        final png = TgaEncoder().encodeImage(image);
        File('$testOutputPath/tga/$name.tga')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }

    test('decode/encode', () {
      final bytes = File('test/_data/tga/globe.tga').readAsBytesSync();

      // Decode the image from file.
      final image = TgaDecoder().decodeImage(bytes)!;
      expect(image.width, equals(128));
      expect(image.height, equals(128));

      // Encode the image as a tga
      final tga = TgaEncoder().encodeImage(image);

      File('$testOutputPath/tga/globe.tga')
        ..createSync(recursive: true)
        ..writeAsBytesSync(tga);

      // Decode the encoded image, make sure it's the same as the original.
      final image2 = TgaDecoder().decodeImage(tga)!;
      expect(image2.width, equals(128));
      expect(image2.height, equals(128));
    });
  });
}
