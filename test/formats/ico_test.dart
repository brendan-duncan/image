import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/ico_encoder.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void IcoTest() {
  group('ICO', () {
    test('encode', () {
      final image = Image(64, 64);
      image.clear(ColorRgb8(100, 200, 255));

      // Encode the image to ICO
      final ico = IcoEncoder().encodeImage(image);
      File('$tmpPath/out/ico/encode.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(ico);

      final image2 = Image(64, 64);
      image2.clear(ColorRgb8(100, 255, 200));

      final ico2 = IcoEncoder().encodeImages([image, image2]);
      File('$tmpPath/out/ico/encode2.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(ico2);

      final image3 = Image(32, 64);
      image3.clear(ColorRgb8(255, 100, 200));

      final ico3 = IcoEncoder().encodeImages([image, image2, image3]);
      File('$tmpPath/out/ico/encode3.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(ico3);
    });

    final dir = Directory('test/data/ico');
    if (!dir.existsSync()) {
      return;
    }

    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.ico')) {
        continue;
      }

      final name = file.uri.pathSegments.last;
      test('decode $name', () {
        final bytes = file.readAsBytesSync();
        final image = IcoDecoder().decodeImageLargest(bytes)!;
        final i8 = image.convert(format: Format.uint8);
        File('$tmpPath/out/ico/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i8));
      });
    }
  });
}
