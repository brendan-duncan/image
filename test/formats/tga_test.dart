import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    final dir = Directory('test/_data/tga');
    if (!dir.existsSync()) {
      return;
    }
    final files = dir.listSync();

    group('tga', () {
      for (final f in files.whereType<File>()) {
        if (!f.path.endsWith('.tga')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final bytes = f.readAsBytesSync();
          final image = TgaDecoder().decode(bytes);
          expect(image, isNotNull);

          encodePngFile('$testOutputPath/tga/$name.png', image!);
          encodeTgaFile('$testOutputPath/tga/$name.tga', image);
        });
      }
    });
  });
}
