import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void NormalizeTest() {
  test('normalize', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    normalize(i0, 50, 150);
    File('$tmpPath/out/filter/normalize.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
