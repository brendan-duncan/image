import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// Known dimensions of the test files, so a decoder regression that changes
// the reported size is caught.
const _expectedSize = <String, List<int>>{
  'test.pbm': [24, 7],
  'test.pgm': [24, 7],
  'test.ppm': [4, 4],
  'z00n2c08.pnm': [32, 32],
};

void main() {
  group('Format', () {
    final dir = Directory('test/_data/pnm');
    if (!dir.existsSync()) {
      return;
    }
    final files = dir.listSync();

    group('pnm', () {
      for (final f in files.whereType<File>()) {
        final name = f.uri.pathSegments.last;
        test(name, () async {
          final bytes = f.readAsBytesSync();

          final decoder = PnmDecoder();
          expect(decoder.isValidFile(bytes), isTrue);

          final image = decoder.decode(bytes);
          expect(image, isNotNull);

          await encodePngFile('$testOutputPath/pnm/$name.png', image!);

          // The decoded image has the expected dimensions.
          final size = _expectedSize[name];
          if (size != null) {
            expect(image.width, equals(size[0]), reason: '$name width');
            expect(image.height, equals(size[1]), reason: '$name height');
          }

          // Decoding is deterministic: a second decode yields identical pixels.
          final image2 = PnmDecoder().decode(bytes)!;
          expect(hashImage(image2), equals(hashImage(image)),
              reason: '$name re-decode');
        });
      }
    });
  });
}
