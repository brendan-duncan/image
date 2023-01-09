import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawLine', () {
      final i0 = Image(width: 256, height: 256);
      drawLine(i0,
          x1: 0, y1: 0, x2: 255, y2: 255, color: ColorRgb8(255, 255, 255));
      drawLine(i0,
          x1: 255,
          y1: 0,
          x2: 0,
          y2: 255,
          color: ColorRgb8(255, 0, 0),
          antialias: true,
          thickness: 4);

      File('$testOutputPath/draw/drawLine.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('drawLineWu', () {
      final i0 = Image(width: 800, height: 400);

      for (int x = 0; x < 400; x += 10) {
        drawLine(i0,
            x1: 400,
            y1: 0,
            x2: x,
            y2: 400,
            color: ColorRgb8(0, 255, 0),
            antialias: true,
            thickness: 1.1);
      }
      for (int x = 400; x <= 800; x += 10) {
        drawLine(i0,
            x1: 400,
            y1: 0,
            x2: x,
            y2: 400,
            color: ColorRgb8(255, 0, 0),
            antialias: true);
      }

      File('$testOutputPath/draw/drawLineWu.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
