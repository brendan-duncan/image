import 'dart:io';
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
