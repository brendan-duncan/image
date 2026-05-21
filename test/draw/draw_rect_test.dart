import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawRect', () {
      final i0 = Image(width: 256, height: 256);

      drawRect(
        i0,
        x1: 50,
        y1: 50,
        x2: 150,
        y2: 150,
        color: ColorRgb8(255, 0, 0),
      );

      drawRect(
        i0,
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 200,
        color: ColorRgba8(0, 255, 0, 128),
        thickness: 14,
      );

      drawRect(
        i0,
        x1: 75,
        y1: 75,
        x2: 175,
        y2: 175,
        color: ColorRgb8(0, 0, 255),
        radius: 20,
      );

      var p = i0.getPixel(50, 50);
      expect(p, equals([255, 0, 0]));

      p = i0.getPixel(100, 100);
      expect(p, equals([0, 128, 0]));

      File('$testOutputPath/draw/drawRect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('drawRect draws only the outline, leaving the interior unchanged', () {
      // Use a fresh black image and a rect well inside the image bounds.
      final image = Image(width: 60, height: 60);
      const x1 = 10;
      const y1 = 10;
      const x2 = 50;
      const y2 = 50;
      const cx = (x1 + x2) ~/ 2; // center x = 30
      const cy = (y1 + y2) ~/ 2; // center y = 30
      final red = ColorRgb8(255, 0, 0);
      drawRect(image,
          x1: x1, y1: y1, x2: x2, y2: y2, color: red, blend: BlendMode.direct);

      // Top-left corner must be the draw color.
      expect(image.getPixel(x1, y1), equals([255, 0, 0]),
          reason: 'top-left corner ($x1,$y1) should be red');

      // Top-right corner must be the draw color.
      expect(image.getPixel(x2, y1), equals([255, 0, 0]),
          reason: 'top-right corner ($x2,$y1) should be red');

      // Bottom-left corner must be the draw color.
      expect(image.getPixel(x1, y2), equals([255, 0, 0]),
          reason: 'bottom-left corner ($x1,$y2) should be red');

      // Bottom-right corner must be the draw color.
      expect(image.getPixel(x2, y2), equals([255, 0, 0]),
          reason: 'bottom-right corner ($x2,$y2) should be red');

      // A pixel mid-way along the top edge must be the draw color.
      expect(image.getPixel(cx, y1), equals([255, 0, 0]),
          reason: 'mid-top edge ($cx,$y1) should be red');

      // drawRect is OUTLINE only: the interior center must be untouched.
      expect(image.getPixel(cx, cy), equals([0, 0, 0]),
          reason: 'interior center ($cx,$cy) should remain black');

      // A pixel well outside the rect should also be untouched.
      expect(image.getPixel(0, 0), equals([0, 0, 0]),
          reason: 'pixel outside rect (0,0) should remain black');
    });

    test('drawRect returns the image (mutates in place)', () {
      final image = Image(width: 20, height: 20);
      final result = drawRect(image,
          x1: 2, y1: 2, x2: 18, y2: 18, color: ColorRgb8(1, 2, 3));
      // drawRect should return the same object.
      expect(identical(result, image), isTrue,
          reason: 'drawRect should return the same Image object');
    });
  });
}
