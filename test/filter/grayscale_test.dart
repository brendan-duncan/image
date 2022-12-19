import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void grayscaleTest() {
  test('grayscale', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    grayscale(i0);
    File('$testOutputPath/filter/grayscale.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
