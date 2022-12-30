import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('pvrtc', () {
      test('globe', () {
        final bytes = File('test/_data/pvr/globe.pvr').readAsBytesSync();
        final image = PvrDecoder().decode(bytes)!;
        File('$testOutputPath/pvr/globe.pvr.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
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
          });
        }
      });
    });
  });
}
