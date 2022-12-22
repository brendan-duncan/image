import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void bmpTest() {
  group('bmp', () {
    final dir = Directory('test/_data/bmp');
    final files = dir.listSync().whereType<File>();
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.bmp')) {
        continue;
      }

      final name = f.uri.pathSegments.last;
      test(name, () {
        final bytes = f.readAsBytesSync();
        final image = BmpDecoder().decode(bytes);
        if (image == null) {
          throw ImageException('Unable to decode BMP Image: $name.');
        }

        final bmp = BmpEncoder().encode(image);
        File('$testOutputPath/bmp/$name.bmp')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bmp);

        final image2 = BmpDecoder().decode(bmp)!;

        testImageEquals(image2, image);

        final bmp2 = BmpEncoder().encode(image2);
        File('$testOutputPath/bmp/${name}2.bmp')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bmp2);
      });
    }
  });
}
