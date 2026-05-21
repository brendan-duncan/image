import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawCircle', () {
      final i0 = Image(width: 256, height: 256);

      drawCircle(
        i0,
        x: 128,
        y: 128,
        radius: 50,
        color: ColorRgba8(255, 0, 0, 255),
      );

      drawCircle(
        i0,
        x: 128,
        y: 128,
        radius: 100,
        antialias: true,
        color: ColorRgba8(0, 255, 0, 255),
      );

      File('$testOutputPath/draw/drawCircle.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('drawCircle draws only outline: axis points painted, center not', () {
      // calculateCircumference always includes the four axis-aligned points:
      // (cx-r, cy), (cx+r, cy), (cx, cy-r), (cx, cy+r).
      final image = Image(width: 100, height: 100);
      const cx = 50;
      const cy = 50;
      const r = 20;
      drawCircle(image,
          x: cx,
          y: cy,
          radius: r,
          color: ColorRgb8(255, 0, 0),
          blend: BlendMode.direct);

      // The four cardinal points on the circumference must be painted.
      expect(image.getPixel(cx - r, cy), equals([255, 0, 0]),
          reason: 'left-most point of circle should be red');
      expect(image.getPixel(cx + r, cy), equals([255, 0, 0]),
          reason: 'right-most point of circle should be red');
      expect(image.getPixel(cx, cy - r), equals([255, 0, 0]),
          reason: 'top-most point of circle should be red');
      expect(image.getPixel(cx, cy + r), equals([255, 0, 0]),
          reason: 'bottom-most point of circle should be red');

      // drawCircle is OUTLINE only: the center must NOT be painted.
      expect(image.getPixel(cx, cy), equals([0, 0, 0]),
          reason: 'center of circle should remain black (outline only)');

      // A pixel well outside the circle should be unchanged.
      expect(image.getPixel(0, 0), equals([0, 0, 0]),
          reason: 'pixel well outside the circle should remain black');
    });

    test('drawCircle returns the image (mutates in place)', () {
      final image = Image(width: 50, height: 50);
      final result = drawCircle(image,
          x: 25, y: 25, radius: 10, color: ColorRgb8(1, 2, 3));
      // drawCircle must return the same object it received.
      expect(identical(result, image), isTrue,
          reason: 'drawCircle should return the same Image object');
    });
  });
}
