import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawLine', () {
      final i0 = Image(width: 256, height: 256);
      drawLine(i0, x1: 0, y1: 0, x2: 255, y2: 255,
          color: ColorRgb8(255, 255, 255));
      drawLine(i0, x1: 255, y1: 0, x2: 0, y2: 255,
          color: ColorRgb8(255, 0, 0),
          antialias: true, thickness: 4);

      File('$testOutputPath/draw/drawLine.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
