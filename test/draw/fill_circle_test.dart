import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void fillCircleTest() {
  test('fillCircle', () {
    final i0 = Image(256, 256);

    fillCircle(i0, 128, 128, 100, ColorRgba8(255, 255, 0, 128));

    File('$testOutputPath/draw/fill_circle_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
