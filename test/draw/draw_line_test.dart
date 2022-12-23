import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';
import '../test_util.dart';

void drawLineTest() {
  test('drawLine', () {
    final i0 = Image(256, 256);
    drawLine(i0, 0, 0, 255, 255, ColorRgb8(255, 255, 255));
    drawLine(i0, 255, 0, 0, 255, ColorRgb8(255),
        antialias: true, thickness: 4);

    File('$testOutputPath/draw/draw_line.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
