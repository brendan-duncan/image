import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void PsdTest() {
  final dir = Directory('test/data/psd');
  final files = dir.listSync();

  group('PSD', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.psd')) {
        continue;
      }

      final name = f.uri.pathSegments.last;
      test(name, () {
        final psd = PsdDecoder().decodeImage(f.readAsBytesSync());
        expect(psd, isNotNull);
        File('$tmpPath/out/psd/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(psd!));
      });
    }
  });
}
