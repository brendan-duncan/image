import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// Known dimensions of the test files, so a decoder regression that changes
// the reported size is caught.
const _expectedSize = <String, List<int>>{
  'buck_16.tga': [300, 186],
  'buck_16_rle.tga': [300, 186],
  'buck_24.tga': [300, 186],
  'buck_24_rle.tga': [300, 186],
  'buck_32.tga': [300, 186],
  'buck_32_rle.tga': [300, 186],
  'buck_8p.tga': [300, 186],
  'globe.tga': [128, 128],
};

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

          // The decoded image has the expected dimensions.
          final size = _expectedSize[name];
          if (size != null) {
            expect(image.width, equals(size[0]), reason: '$name width');
            expect(image.height, equals(size[1]), reason: '$name height');
          }

          // TGA is lossless: decode -> encode -> decode preserves every pixel
          // value. A paletted source may re-encode as direct color, so the
          // materialized pixels are compared rather than the palette
          // representation.
          final reDecoded = TgaDecoder().decode(TgaEncoder().encode(image));
          expect(reDecoded, isNotNull);
          final nc = image.numChannels;
          testImageEquals(
            reDecoded!.convert(format: Format.uint8, numChannels: nc),
            image.convert(format: Format.uint8, numChannels: nc),
          );
        });
      }
    });
  });
}
