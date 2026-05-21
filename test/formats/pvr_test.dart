import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// Known dimensions of the test textures, so a decoder regression that changes
// the reported size is caught.
const _expectedSize = <String, List<int>>{
  'AI88.pvr': [256, 256],
  'apple_4bpp.pvr': [256, 256],
  'globe.pvr': [128, 128],
  'I8.pvr': [256, 256],
  'RGB565.pvr': [256, 256],
  'RGB888.pvr': [256, 256],
  'RGBA4444.pvr': [256, 256],
  'RGBA5551.pvr': [256, 256],
  'RGBA8888.pvr': [256, 256],
};

void main() {
  group('Format', () {
    group('pvrtc', () {
      test('globe', () {
        final bytes = File('test/_data/pvr/globe.pvr').readAsBytesSync();
        final image = PvrDecoder().decode(bytes)!;
        File('$testOutputPath/pvr/globe.pvr.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));

        // globe.pvr is a 128x128 texture.
        expect(image.width, equals(128));
        expect(image.height, equals(128));
      });

      group('decode', () {
        final dir = Directory('test/_data/pvr');
        final files = dir.listSync();
        for (var f in files.whereType<File>()) {
          if (!f.path.endsWith('.pvr')) {
            continue;
          }
          final name = f.uri.pathSegments.last;
          test(name, () {
            final bytes = f.readAsBytesSync();
            final img = PvrDecoder().decode(bytes)!;
            File('$testOutputPath/pvr/$name.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodePng(img));

            // The decoded texture has the expected dimensions.
            final size = _expectedSize[name];
            if (size != null) {
              expect(img.width, equals(size[0]), reason: '$name width');
              expect(img.height, equals(size[1]), reason: '$name height');
            }

            // Decoding is deterministic: a second decode yields the same data.
            final img2 = PvrDecoder().decode(bytes)!;
            expect(hashImage(img2), equals(hashImage(img)),
                reason: '$name re-decode');
          });
        }
      });
    });
  });
}
