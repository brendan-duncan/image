import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillCircle', () async {
      await (Command()
            ..createImage(width: 256, height: 256, numChannels: 4)
            ..fillCircle(
              x: 128,
              y: 128,
              radius: 100,
              antialias: true,
              color: ColorRgba8(255, 255, 0, 200),
            )
            ..fillCircle(
              x: 128,
              y: 128,
              radius: 50,
              color: ColorRgba8(0, 255, 0, 255),
            )
            ..writeToFile('$testOutputPath/draw/fillCircle.png'))
          .execute();
    });

    test('fillCircleWithBlendDirect', () async {
      await (Command()
            ..createImage(width: 256, height: 256, numChannels: 4)
            ..fillCircle(
              x: 128,
              y: 128,
              radius: 100,
              antialias: true,
              color: ColorRgba8(255, 255, 0, 200),
            )
            ..fillCircle(
              x: 128,
              y: 128,
              radius: 50,
              // Will force setting a central area to transparent
              color: ColorRgba8(0, 255, 0, 0),
              blend: BlendMode.direct,
            )
            ..writeToFile('$testOutputPath/draw/'
                'fillCircleWithBlendDirect.png'))
          .execute();
    });

    test('fillCircle fills interior: center has the draw color', () {
      // fillCircle uses d2 < radiusSqr, so every pixel strictly inside
      // the radius is painted, including the center (d2 == 0).
      final image = Image(width: 100, height: 100);
      const cx = 50;
      const cy = 50;
      const r = 20;
      fillCircle(image,
          x: cx,
          y: cy,
          radius: r,
          color: ColorRgb8(255, 0, 0),
          blend: BlendMode.direct);

      // The center pixel must be painted (d2 == 0 < r^2).
      expect(image.getPixel(cx, cy), equals([255, 0, 0]),
          reason: 'center of filled circle should be red');

      // A pixel one step inside the radius should also be painted.
      expect(image.getPixel(cx, cy + r - 1), equals([255, 0, 0]),
          reason: 'pixel near inner edge should be red');

      // Pixels well outside the radius must remain black.
      expect(image.getPixel(0, 0), equals([0, 0, 0]),
          reason: 'pixel well outside circle should remain black');
      expect(image.getPixel(cx, cy + r + 2), equals([0, 0, 0]),
          reason: 'pixel outside circle radius should remain black');
    });

    test('fillCircle returns the image (mutates in place)', () {
      final image = Image(width: 50, height: 50);
      final result = fillCircle(image,
          x: 25, y: 25, radius: 10, color: ColorRgb8(1, 2, 3));
      // fillCircle must return the same object it received.
      expect(identical(result, image), isTrue,
          reason: 'fillCircle should return the same Image object');
    });
  });
}
