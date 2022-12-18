import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void ScaleRgbaTest() {
  test('scaleRgba', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    scaleRgba(i0, ColorRgb8(128, 128, 128));
    File('$tmpPath/out/filter/scaleRgba.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
