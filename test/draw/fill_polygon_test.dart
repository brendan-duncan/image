import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillPolygon', () {
      final i0 = Image(width: 256, height: 256);

      final vertices = <Point>[Point(50, 50), Point(200, 20),
        Point(120, 70), Point(30, 150)];

      fillPolygon(i0, vertices: vertices, color: ColorRgb8(176, 0, 0));
      //drawPolygon(i0, vertices: vertices, color: ColorRgb8(0, 255, 0));

      File('$testOutputPath/draw/fillPolygon.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
