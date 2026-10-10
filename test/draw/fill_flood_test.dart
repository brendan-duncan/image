import 'dart:io';
import 'dart:math' show sqrt;

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Distance from ([x],[y]) to the circle center at (50,50).
double _dist(num x, num y) => sqrt((x - 50) * (x - 50) + (y - 50) * (y - 50));

/// Expects the radius 49 red outline to still be intact.
void _expectCircleOutline(Image img) {
  for (final (x, y) in [(1, 50), (99, 50), (50, 1), (50, 99)]) {
    expect(img.getPixel(x, y), equals([255, 0, 0]), reason: 'outline $x,$y');
  }
}

void main() {
  group('Draw', () {
    test('fillFlood: seed pixel becomes fill color', () {
      // A plain black image: flood-filling from (5,5) should paint the whole
      // image because every pixel has the same color as the seed.
      final img = solidImage(20, 20, ColorRgb8(0, 0, 0));
      final fillColor = ColorRgb8(0, 200, 0);
      fillFlood(img, x: 5, y: 5, color: fillColor);
      // seed pixel itself must now be the fill color
      final seed = img.getPixel(5, 5);
      expect(seed.r, equals(0));
      expect(seed.g, equals(200));
      expect(seed.b, equals(0));
    });

    test('fillFlood: connected region is filled; separated region is not', () {
      // Draw a vertical dividing line in the middle of a 40-wide image.
      // Flood-fill from the left side must not cross to the right side.
      final img = Image(width: 40, height: 20);
      // draw a solid red vertical wall at x=19..20
      for (var y = 0; y < 20; y++) {
        img
          ..setPixel(19, y, ColorRgb8(255, 0, 0))
          ..setPixel(20, y, ColorRgb8(255, 0, 0));
      }
      final fillColor = ColorRgb8(0, 0, 255);
      fillFlood(img, x: 5, y: 10, color: fillColor, threshold: 0);

      // a pixel on the left side should be filled
      final left = img.getPixel(5, 10);
      expect(left.b, equals(255),
          reason: 'left region should be filled with blue');

      // a pixel on the right side must remain black (not crossed the wall)
      final right = img.getPixel(35, 10);
      expect(right.r, equals(0));
      expect(right.g, equals(0));
      expect(right.b, equals(0));
    });

    test('fillFlood: image dimensions unchanged after fill', () {
      final img = Image(width: 30, height: 30);
      fillFlood(img, x: 15, y: 15, color: ColorRgb8(128, 0, 128));
      expect(img.width, equals(30));
      expect(img.height, equals(30));
    });

    test('fillFlood', () async {
      final img = Image(width: 100, height: 100);
      drawCircle(img, x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0));
      fillFlood(img, x: 50, y: 50, color: ColorRgb8(0, 255, 0), threshold: 1);

      File('$testOutputPath/draw/fillFlood.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(img));

      // The fill covers the inside of the circle, stops at the red outline
      // and does not leak to the outside.
      _expectCircleOutline(img);
      for (final p in img) {
        final d = _dist(p.x, p.y);
        if (d < 47.5) {
          expect(p, equals([0, 255, 0]), reason: 'inside ${p.x},${p.y}');
        } else if (d > 50.5) {
          expect(p, equals([0, 0, 0]), reason: 'outside ${p.x},${p.y}');
        }
      }

      final mask = Command()
        ..createImage(width: 100, height: 100)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(x: 50, y: 50, radius: 25, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 5);

      final masked = (await (Command()
            ..createImage(width: 100, height: 100)
            ..drawCircle(x: 50, y: 50, radius: 49, color: ColorRgb8(255, 0, 0))
            ..fillFlood(
              x: 50,
              y: 50,
              color: ColorRgb8(0, 255, 0),
              threshold: 1,
              mask: mask,
            )
            ..writeToFile('$testOutputPath/draw/fillFlood_mask.png'))
          .getImage())!;

      // Inside the outline the fill strength follows the mask: strong in the
      // middle, fading with the blurred edge and absent where it is black.
      final maskImage = (await mask.getImage())!;
      _expectCircleOutline(masked);
      for (final p in masked) {
        final d = _dist(p.x, p.y);
        if (d < 47.5) {
          final m = maskImage.getPixel(p.x, p.y).luminanceNormalized;
          expect(p.g, closeTo(255 * m, 1), reason: 'inside ${p.x},${p.y}');
          expect(p.r, equals(0), reason: 'inside ${p.x},${p.y}');
          expect(p.b, equals(0), reason: 'inside ${p.x},${p.y}');
        } else if (d > 50.5) {
          expect(p, equals([0, 0, 0]), reason: 'outside ${p.x},${p.y}');
        }
      }
      expect(masked.getPixel(50, 50).g, greaterThan(250), reason: 'center');
      expect(masked.getPixel(50 + 25, 50).g, inExclusiveRange(0, 250),
          reason: 'blurred mask edge');
      expect(masked.getPixel(50 + 40, 50), equals([0, 0, 0]),
          reason: 'masked out');
    });
  });
}
