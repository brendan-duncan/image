import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('compositeImage', () {
      final fg = Command()
        ..decodeTgaFile('test/_data/tga/globe.tga')
        ..convert(numChannels: 4)
        ..filter((image) {
          for (final p in image) {
            if (p.r == 0 && p.g == 0 && p.b == 0) {
              p.a = 0;
            }
          }
          return image;
        });

      Command()
        ..decodePngFile('test/_data/png/buck_24.png')
        ..compositeImage(fg, dstX: 50, dstY: 50)
        ..writeToFile('$testOutputPath/cmd/compositeImage.png')
        ..execute();
    });
  });
}
