import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fill', () async {
      final cmd = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgba8(120, 64, 85, 90))
        ..encodePng();

      final png = await cmd.getBytesThread();
      expect(png, isNotNull);
      File('$testOutputPath/draw/fill.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!);

      final img = await cmd.getImageThread();
      expect(img, isNotNull);
      expect(img?.width, equals(256));
      expect(img?.height, equals(256));
      expect(img?.getPixel(0, 0), equals([120, 64, 85]));

      final mask = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
            x: 128, y: 128, radius: 50, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 10);

      await (Command()
            ..createImage(width: 256, height: 256)
            ..fill(color: ColorRgb8(255, 255, 255))
            ..fill(color: ColorRgb8(255, 0, 0), mask: mask)
            ..writeToFile('$testOutputPath/draw/fill_mask.png'))
          .execute();
    });
  });
}
