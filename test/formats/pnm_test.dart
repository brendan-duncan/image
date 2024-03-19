import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

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
          await encodePngFile('$testOutputPath/pnm/$name.png', image);
        });
      }
    });
  });
}
