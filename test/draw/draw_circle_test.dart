import 'dart:io';
import 'dart:math' show sqrt;

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

      // The axis points of both circles have the full circle color.
      for (final (r, color) in [
        (50, [255, 0, 0]),
        (100, [0, 255, 0])
      ]) {
        expect(i0.getPixel(128 - r, 128), equals(color), reason: 'left $r');
        expect(i0.getPixel(128 + r, 128), equals(color), reason: 'right $r');
        expect(i0.getPixel(128, 128 - r), equals(color), reason: 'top $r');
        expect(i0.getPixel(128, 128 + r), equals(color), reason: 'bottom $r');
      }

      // Red only on the radius 50 ring, green only near the radius 100 ring,
      // and everything else, including the center, is untouched.
      for (final p in i0) {
        final d = sqrt((p.x - 128) * (p.x - 128) + (p.y - 128) * (p.y - 128));
        final near50 = (d - 50).abs() <= 1;
        final near100 = (d - 100).abs() <= 1.5;
        if (!near50) {
          expect(p.r, equals(0), reason: 'red at ${p.x},${p.y}');
        }
        if (!near100) {
          expect(p.g, equals(0), reason: 'green at ${p.x},${p.y}');
        }
        expect(p.b, equals(0), reason: 'blue at ${p.x},${p.y}');
      }
      expect(i0.getPixel(128, 128), equals([0, 0, 0]), reason: 'center');
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
