import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void drawRectTest() {
  test('drawRect', () {
    final i0 = Image(256, 256);

    drawRect(i0, 50, 50, 150, 150, ColorRgb8(255));
    drawRect(i0, 100, 100, 200, 200, ColorRgba8(0, 255, 0, 128),
        thickness: 14);

    var p = i0.getPixel(50, 50);
    expect(p, equals([255, 0, 0]));
    p = i0.getPixel(100, 100);
    expect(p, equals([0, 128, 0]));

    File('$testOutputPath/draw/draw_rect_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
