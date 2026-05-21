import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('invert', () async {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final img = decodePng(bytes)!;
      final i0 = img.clone();
      invert(i0);
      File('$testOutputPath/filter/invert.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // invert maps each channel value v to (maxChannelValue - v).
      final orig = img.getPixel(0, 0);
      final inv = i0.getPixel(0, 0);
      expect(inv.r, equals(255 - orig.r), reason: 'inverted red channel');
      expect(inv.g, equals(255 - orig.g), reason: 'inverted green channel');
      expect(inv.b, equals(255 - orig.b), reason: 'inverted blue channel');

      // invert is an involution: applying it twice restores the original.
      testImageEquals(invert(i0), img);

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: img.width ~/ 2,
          y: img.height ~/ 2,
          radius: 80,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 20);

      await (Command()
            ..image(img)
            ..copy()
            ..invert(mask: mask)
            ..writeToFile('$testOutputPath/filter/invert_mask.png'))
          .execute();
    });

    test('invert maps known colors to their complement', () {
      expectSolidColor(invert(solidImage(8, 8, ColorRgb8(0, 0, 0))),
          ColorRgb8(255, 255, 255));
      expectSolidColor(invert(solidImage(8, 8, ColorRgb8(255, 255, 255))),
          ColorRgb8(0, 0, 0));
      expectSolidColor(invert(solidImage(8, 8, ColorRgb8(128, 64, 32))),
          ColorRgb8(127, 191, 223));
    });

    test('invert with an all-zero mask leaves the image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result =
          invert(src.clone(), mask: solidImage(32, 8, ColorRgb8(0, 0, 0)));
      testImageEquals(result, src);
    });
  });
}
