import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawRect', () {
      final i0 = Image(width: 256, height: 256);

      drawRect(i0,
          x1: 50, y1: 50, x2: 150, y2: 150, color: ColorRgb8(255, 0, 0));

      drawRect(i0,
          x1: 100,
          y1: 100,
          x2: 200,
          y2: 200,
          color: ColorRgba8(0, 255, 0, 128),
          thickness: 14);

      drawRect(i0,
          x1: 75,
          y1: 75,
          x2: 175,
          y2: 175,
          color: ColorRgb8(0, 0, 255),
          radius: 20);

      var p = i0.getPixel(50, 50);
      expect(p, equals([255, 0, 0]));

      p = i0.getPixel(100, 100);
      expect(p, equals([0, 128, 0]));

      File('$testOutputPath/draw/drawRect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
