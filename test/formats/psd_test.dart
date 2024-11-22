import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

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
          File('$testOutputPath/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(psd!));

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
