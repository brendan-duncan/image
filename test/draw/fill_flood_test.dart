import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillFlood', () async {
      final img = Image(width: 100, height: 100);
      drawCircle(img, x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0));
      fillFlood(img, x: 50, y: 50, color: ColorRgb8(0, 255, 0), threshold: 1);

      File('$testOutputPath/draw/fillFlood.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(img));

      final mask = Command()
        ..createImage(width: 100, height: 100)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(x: 50, y: 50, radius: 25, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 5);

      await (Command()
            ..createImage(width: 100, height: 100)
            ..drawCircle(x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0))
            ..fillFlood(
                x: 50,
                y: 50,
                color: ColorRgb8(0, 255, 0),
                threshold: 1,
                mask: mask)
            ..writeToFile('$testOutputPath/draw/fillFlood_mask.png'))
          .execute();
    });
  });
}
