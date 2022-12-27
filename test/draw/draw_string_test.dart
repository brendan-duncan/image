import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawString', () {
      final i0 = Image(width: 256, height: 256)
      ..clear(ColorRgb8(128, 128));
      drawString(i0, arial24, 50, 50, "Hello", color: ColorRgba8(255));
      drawString(i0, arial24, 200, 80, "Right Justified", rightJustify: true);
      drawStringCentered(i0, arial24, "Centered");

      File('$testOutputPath/draw/draw_string.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
