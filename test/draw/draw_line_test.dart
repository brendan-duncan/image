import 'dart:io';
import 'dart:math' show max;

import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawLine', () {
      final i0 = Image(width: 256, height: 256);
      drawLine(
        i0,
        x1: 0,
        y1: 0,
        x2: 255,
        y2: 255,
        color: ColorRgb8(255, 255, 255),
      );
      drawLine(
        i0,
        x1: 255,
        y1: 0,
        x2: 0,
        y2: 255,
        color: ColorRgb8(255, 0, 0),
        antialias: true,
        thickness: 4,
      );

      File('$testOutputPath/draw/drawLine.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      for (var i = 0; i < 256; ++i) {
        // The thin white diagonal, except where the red line crosses it.
        if ((i - 128).abs() > 4) {
          expect(i0.getPixel(i, i), equals([255, 255, 255]),
              reason: 'white line at $i,$i');
        }
        // The thick red anti-diagonal is fully opaque along its center.
        expect(i0.getPixel(255 - i, i), equals([255, 0, 0]),
            reason: 'red line at ${255 - i},$i');
      }

      // Pixels away from both lines are untouched.
      for (final p in i0) {
        if ((p.x - p.y).abs() > 1 && (p.x + p.y - 255).abs() > 4) {
          expect(p, equals([0, 0, 0]), reason: 'background at ${p.x},${p.y}');
        }
      }
    });

    test('drawLineWu', () {
      final i0 = Image(width: 800, height: 400);

      for (int x = 0; x < 400; x += 10) {
        drawLine(
          i0,
          x1: 400,
          y1: 0,
          x2: x,
          y2: 400,
          color: ColorRgb8(0, 255, 0),
          antialias: true,
          thickness: 1.1,
        );
      }
      for (int x = 400; x <= 800; x += 10) {
        drawLine(
          i0,
          x1: 400,
          y1: 0,
          x2: x,
          y2: 400,
          color: ColorRgb8(255, 0, 0),
          antialias: true,
        );
      }

      File('$testOutputPath/draw/drawLineWu.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // Each line crosses the middle row near its ideal position, x = 400 at
      // the top and x2 at the bottom.
      for (var x2 = 0; x2 <= 800; x2 += 10) {
        final ideal = (400 + x2) ~/ 2;
        var peak = 0;
        for (var x = ideal - 2; x <= ideal + 2; ++x) {
          final p = i0.getPixel(x, 200);
          peak = max(peak, (x2 < 400 ? p.g : p.r).toInt());
        }
        expect(peak, greaterThan(127), reason: 'line to $x2 at row 200');
      }

      // The vertical line and the 45 degree line are exact pixel runs.
      for (var y = 1; y < 399; ++y) {
        expect(i0.getPixel(400, y), equals([255, 0, 0]), reason: 'x=400 y=$y');
        expect(i0.getPixel(400 + y, y), equals([255, 0, 0]),
            reason: 'diagonal y=$y');
      }

      // Green lines are only on the left, red lines only on the right.
      for (final p in i0) {
        if (p.x < 400) {
          expect(p.r, equals(0), reason: 'red at ${p.x},${p.y}');
        }
        if (p.x > 402) {
          expect(p.g, equals(0), reason: 'green at ${p.x},${p.y}');
        }
      }

      // Pixels above the fan and between line ends are untouched.
      expect(i0.getPixel(0, 0), equals([0, 0, 0]));
      expect(i0.getPixel(100, 10), equals([0, 0, 0]));
      expect(i0.getPixel(700, 10), equals([0, 0, 0]));
      expect(i0.getPixel(387, 399), equals([0, 0, 0]));
      expect(i0.getPixel(414, 399), equals([0, 0, 0]));
    });

    // A non-antialiased line passes exactly through its endpoints.
    test('drawLine non-antialiased passes through its endpoints', () {
      final image = Image(width: 200, height: 120);
      drawLine(image,
          x1: 0, y1: 0, x2: 100, y2: 50, color: ColorRgb8(255, 255, 255));
      // The line has a slope of 0.5, so it should pass exactly through these
      // points with no vertical offset.
      expect(image.getPixel(0, 0).r, equals(255));
      expect(image.getPixel(50, 25).r, equals(255));
      expect(image.getPixel(100, 50).r, equals(255));
    });

    test('drawLine horizontal: every pixel on the line has the draw color', () {
      final image = Image(width: 100, height: 20);
      const lineY = 10;
      const x1 = 10;
      const x2 = 80;
      drawLine(image,
          x1: x1,
          y1: lineY,
          x2: x2,
          y2: lineY,
          color: ColorRgb8(255, 0, 0),
          blend: BlendMode.direct);

      // Every pixel along the horizontal line must be red.
      for (var x = x1; x <= x2; x++) {
        expect(image.getPixel(x, lineY), equals([255, 0, 0]),
            reason: 'pixel ($x,$lineY) should be red');
      }

      // A pixel well off the line should remain black (background).
      expect(image.getPixel(x1, 0), equals([0, 0, 0]),
          reason: 'pixel off the line should remain black');
    });

    test('drawLine vertical: every pixel on the line has the draw color', () {
      final image = Image(width: 20, height: 100);
      const lineX = 5;
      const y1 = 10;
      const y2 = 80;
      drawLine(image,
          x1: lineX,
          y1: y1,
          x2: lineX,
          y2: y2,
          color: ColorRgb8(0, 255, 0),
          blend: BlendMode.direct);

      // Every pixel along the vertical line must be green.
      for (var y = y1; y <= y2; y++) {
        expect(image.getPixel(lineX, y), equals([0, 255, 0]),
            reason: 'pixel ($lineX,$y) should be green');
      }

      // A pixel well off the line should remain black.
      expect(image.getPixel(15, y1), equals([0, 0, 0]),
          reason: 'pixel off the line should remain black');
    });

    test('drawLine returns the image (mutates in place)', () {
      final image = Image(width: 10, height: 10);
      final result = drawLine(image,
          x1: 0, y1: 0, x2: 9, y2: 9, color: ColorRgb8(255, 255, 255));
      // drawLine must return the same object it received.
      expect(identical(result, image), isTrue,
          reason: 'drawLine should return the same Image object');
    });
  });
}
