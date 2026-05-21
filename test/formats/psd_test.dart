import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// Known dimensions of the composited test files, so a decoder regression that
// changes the reported size is caught.
const _expectedSize = <String, List<int>>{
  'index should be less than.psd': [512, 672],
  'index should be less than_2.psd': [1280, 1680],
  'psd1.psd': [32, 32],
  'psd2.psd': [32, 32],
  'psd3.psd': [32, 32],
  'psd4.psd': [32, 32],
  'psd5.psd': [32, 32],
  'psd6.psd': [200, 100],
  'rectangles.psd': [375, 478],
  'rle_crash.psd': [619, 568],
  'Unsupported compression.psd': [1280, 1680],
};

void main() {
  group('Format', () {
    final dir = Directory('test/_data/psd');
    final files = dir.listSync();

    group('psd', () {
      for (final f in files.whereType<File>()) {
        if (!f.path.endsWith('.psd')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final decoder = PsdDecoder();
          final psd = decoder.decode(f.readAsBytesSync());
          expect(psd, isNotNull);
          final image = psd!;

          // The decoded composite has the expected dimensions.
          final size = _expectedSize[name];
          if (size != null) {
            expect(image.width, equals(size[0]), reason: '$name width');
            expect(image.height, equals(size[1]), reason: '$name height');
          }

          File('$testOutputPath/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(image));

          var li = 0;
          for (final layer in decoder.info!.layers) {
            final layerImg = layer.layerImage;
            if (layerImg != null) {
              File('$testOutputPath/psd/${name}_${li}_${layer.name}.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(encodePng(layerImg));
            }
            ++li;
          }
        });
      }
    });
  });
}
