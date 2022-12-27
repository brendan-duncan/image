import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawLine', () {
      final i0 = Image(width: 256, height: 256);
      drawLine(i0, 0, 0, 255, 255, ColorRgb8(255, 255, 255));
      drawLine(i0, 255, 0, 0, 255, ColorRgb8(255),
          antialias: true, thickness: 4);

      File('$testOutputPath/draw/draw_line.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
