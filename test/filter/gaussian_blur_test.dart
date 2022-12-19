import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void GaussianBlurTest() {
  test('gaussianBlur', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    gaussianBlur(i0, 10);
    File('$tmpPath/out/filter/gaussianBlur.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}