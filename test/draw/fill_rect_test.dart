import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillRect', () async {
      final i0 = Image(width: 256, height: 256);

      fillRect(i0,
          x1: 50, y1: 50, x2: 150, y2: 150, color: ColorRgb8(255, 0, 0));

      fillRect(i0,
          x1: 100,
          y1: 100,
          x2: 200,
          y2: 200,
          color: ColorRgba8(0, 255, 0, 128));

      fillRect(i0,
          x1: 75,
          y1: 75,
          x2: 175,
          y2: 175,
          radius: 20,
          color: ColorRgba8(255, 255, 0, 128));

      File('$testOutputPath/draw/fillRect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      var p = i0.getPixel(51, 51);
      expect(p, equals([255, 0, 0]));

      p = i0.getPixel(195, 195);
      expect(p, equals([0, 128, 0]));

      final mask = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
            x: 128, y: 128, radius: 50, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 10);

      await (Command()
            ..createImage(width: 256, height: 256)
            ..fill(color: ColorRgb8(255, 255, 255))
            ..fillRect(
                x1: 50, y1: 50, x2: 150, y2: 150, color: ColorRgb8(255, 0, 0))
            ..fillRect(
                x1: 100,
                y1: 100,
                x2: 200,
                y2: 200,
                color: ColorRgba8(0, 255, 0, 128),
                mask: mask,
                maskChannel: Channel.red)
            ..writeToFile('$testOutputPath/draw/fillRect_mask.png'))
          .execute();
    });
  });
}
