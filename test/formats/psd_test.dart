import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    final dir = Directory('test/_data/psd');
    final files = dir.listSync();

    group('psd', () {
      for (var f in files.whereType<File>()) {
        if (!f.path.endsWith('.psd')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final psd = PsdDecoder().decode(f.readAsBytesSync());
          expect(psd, isNotNull);
          File('$testOutputPath/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(psd!));
        });
      }
    });
  });
}
