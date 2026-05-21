import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillRect', () async {
      final i0 = Image(width: 256, height: 256, numChannels: 4);

      fillRect(
        i0,
        x1: 50,
        y1: 50,
        x2: 150,
        y2: 150,
        color: ColorRgb8(255, 0, 0),
      );

      fillRect(
        i0,
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 200,
        color: ColorRgba8(0, 255, 0, 128),
      );

      fillRect(
        i0,
        x1: 75,
        y1: 75,
        x2: 175,
        y2: 175,
        radius: 20,
        color: ColorRgba8(255, 255, 0, 128),
      );

      File('$testOutputPath/draw/fillRect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      var p = i0.getPixel(51, 51);
      expect(p, equals([255, 0, 0, 255]));

      p = i0.getPixel(195, 195);
      expect(p, equals([0, 128, 0, 128]));

      // The red fill covered 50..150; pixel at (40,40) is untouched background.
      expect(i0.getPixel(40, 40), equals([0, 0, 0, 0]),
          reason: 'pixel outside all rects should remain transparent black');

      final mask = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: 128,
          y: 128,
          radius: 50,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 10);

      await (Command()
            ..createImage(width: 256, height: 256)
            ..fill(color: ColorRgb8(255, 255, 255))
            ..fillRect(
              x1: 50,
              y1: 50,
              x2: 150,
              y2: 150,
              color: ColorRgb8(255, 0, 0),
            )
            ..fillRect(
              x1: 100,
              y1: 100,
              x2: 200,
              y2: 200,
              color: ColorRgba8(0, 255, 0, 128),
              mask: mask,
              maskChannel: Channel.red,
            )
            ..writeToFile('$testOutputPath/draw/fillRect_mask.png'))
          .execute();
    });

    test('fillRect fills interior: center and edges have the draw color', () {
      final image = Image(width: 60, height: 60);
      const x1 = 10;
      const y1 = 10;
      const x2 = 50;
      const y2 = 50;
      // alphaBlend:false forces a direct pixel-set with no blending math.
      fillRect(image,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: ColorRgb8(255, 0, 0),
          alphaBlend: false);

      // Corners of the rect must be painted.
      expect(image.getPixel(x1, y1), equals([255, 0, 0]),
          reason: 'top-left corner should be red');
      expect(image.getPixel(x2, y2), equals([255, 0, 0]),
          reason: 'bottom-right corner should be red');

      // Interior center must be painted (fillRect is a FILL, not outline).
      const cx = (x1 + x2) ~/ 2;
      const cy = (y1 + y2) ~/ 2;
      expect(image.getPixel(cx, cy), equals([255, 0, 0]),
          reason: 'interior center ($cx,$cy) should be red');

      // Pixels just outside the rect must remain black.
      expect(image.getPixel(x1 - 1, y1), equals([0, 0, 0]),
          reason: 'pixel just left of rect should remain black');
      expect(image.getPixel(x1, y1 - 1), equals([0, 0, 0]),
          reason: 'pixel just above rect should remain black');
      expect(image.getPixel(x2 + 1, y2), equals([0, 0, 0]),
          reason: 'pixel just right of rect should remain black');
      expect(image.getPixel(x2, y2 + 1), equals([0, 0, 0]),
          reason: 'pixel just below rect should remain black');
    });

    test('fillRect returns the image (mutates in place)', () {
      final image = Image(width: 20, height: 20);
      final result = fillRect(image,
          x1: 2, y1: 2, x2: 18, y2: 18, color: ColorRgb8(1, 2, 3));
      // fillRect must return the same object it received.
      expect(identical(result, image), isTrue,
          reason: 'fillRect should return the same Image object');
    });

    test('fillRect with alpha=0 leaves the image unchanged', () {
      final src = solidImage(20, 20, ColorRgb8(100, 100, 100));
      // alphaBlend=true and color.a==0 triggers the early-return in fillRect.
      fillRect(src,
          x1: 5,
          y1: 5,
          x2: 15,
          y2: 15,
          color: ColorRgba8(255, 0, 0, 0));
      expectSolidColor(src, ColorRgb8(100, 100, 100),
          reason: 'fillRect with alpha=0 should not change any pixel');
    });
  });
}
