import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawString', () {
      final i0 = Image(width: 256, height: 256)..clear(ColorRgb8(128, 128, 0));
      drawString(i0, "Hello",
          font: arial24, x: 50, y: 50, color: ColorRgba8(255, 0, 0, 128));
      drawString(i0, "Right Justified",
          font: arial24, x: 200, y: 80, rightJustify: true);
      drawString(i0, "Centered", font: arial24);

      File('$testOutputPath/draw/drawString.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
