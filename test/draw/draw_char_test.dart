import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void DrawCharTest() {
  test('drawChar', () {
    final i0 = Image(256, 256);

    i0.clear(ColorRgb8(128, 128));
    drawChar(i0, arial24, 50, 50, "H");
    drawChar(i0, arial24, 70, 70, "e", color: ColorRgba8(255));
    drawChar(i0, arial24, 90, 90, "l", color: ColorRgba8(0, 255));
    drawChar(i0, arial24, 110, 110, "l", color: ColorRgba8(0, 0, 255));
    drawChar(i0, arial24, 130, 130, "o", color: ColorRgba8(255, 0, 0, 128));

    File('$tmpPath/out/draw/draw_char_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
