import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void FillFloodTest() {
  test('fillFlood', () {
    final img = Image(100, 100);
    drawCircle(img, 50, 50, 49, ColorRgb8(255));
    fillFlood(img, 50, 50, ColorRgb8(0, 255, 0), threshold: 1);
    File('$tmpPath/out/draw/fillFlood.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(img));
  });
}
