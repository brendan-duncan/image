import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('reinhardTonemap', () async {
      final hdr = (await decodeExrFile('test/_data/exr/ocean.exr'))!;

      reinhardTonemap(hdr);
      final ldr = hdrToLdr(hdr, exposure: -1);

      File('$testOutputPath/filter/reinhardTonemap.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ldr));
    });
  });
}
