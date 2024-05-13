import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/ico_encoder.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('ico', () {
      test('encode palette', () async {
        var img = await decodePngFile('test/_data/png/buck_8.png');
        img = copyResize(img!, width: 256);
        img = vignette(img);
        final ico = IcoEncoder().encode(img);
        File('$testOutputPath/ico/buck_8.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico);
      });

      test('encode', () {
        final image = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 200, 255));

        // Encode the image to ICO
        final ico = IcoEncoder().encode(image);
        File('$testOutputPath/ico/encode.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico);

        final image2 = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 255, 200));

        final ico2 = IcoEncoder().encodeImages([image, image2]);
        File('$testOutputPath/ico/encode2.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico2);

        final image3 = Image(width: 32, height: 64)
          ..clear(ColorRgb8(255, 100, 200));

        final ico3 = IcoEncoder().encodeImages([image, image2, image3]);
        File('$testOutputPath/ico/encode3.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico3);
      });

      final dir = Directory('test/_data/ico');
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
          File('$testOutputPath/ico/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(i8));
        });
      }
    });
  });
}
