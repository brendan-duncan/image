import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void psdTest() {
  final dir = Directory('test/_data/psd');
  final files = dir.listSync();

  group('psd', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.psd')) {
        continue;
      }

      final name = f.uri.pathSegments.last;
      test(name, () {
        final psd = PsdDecoder().decodeImage(f.readAsBytesSync());
        expect(psd, isNotNull);
        File('$testOutputPath/psd/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(psd!));
      });
    }
  });
}
