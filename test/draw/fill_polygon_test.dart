import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Expects the [fill] points to be the fill color, the [background] points
/// untouched and the [outline] points the outline color.
void _expectPixels(Image img,
    {required Iterable<(int, int)> fill,
    required Iterable<(int, int)> background,
    required Iterable<(int, int)> outline}) {
  for (final (x, y) in fill) {
    expect(img.getPixel(x, y), equals([176, 0, 0]), reason: 'fill $x,$y');
  }
  for (final (x, y) in background) {
    expect(img.getPixel(x, y), equals([0, 0, 0]), reason: 'outside $x,$y');
  }
  for (final (x, y) in outline) {
    expect(img.getPixel(x, y), equals([0, 255, 0]), reason: 'outline $x,$y');
  }
}

void main() {
  group('Draw', () {
    test('fillPolygon', () async {
      final i0 = Image(width: 256, height: 256);

      final vertices = <Point>[
        Point(50, 50),
        Point(200, 20),
        Point(120, 70),
        Point(30, 150),
      ];

      fillPolygon(i0, vertices: vertices, color: ColorRgb8(176, 0, 0));
      drawPolygon(i0, vertices: vertices, color: ColorRgb8(0, 255, 0));

      File('$testOutputPath/draw/fillPolygon.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      _expectPixels(
        i0,
        // Interior points, including inside both wings of the arrowhead.
        fill: [(60, 60), (100, 50), (150, 40), (50, 120), (80, 80)],
        // Outside, including the notch below the reflex vertex (120,70).
        background: [(10, 10), (250, 250), (110, 100), (150, 70), (40, 30)],
        // The outline is drawn over the fill at the vertices.
        outline: vertices.map((p) => (p.xi, p.yi)),
      );
    });

    test('fillPolygon concave', () async {
      final i0 = Image(width: 256, height: 256);

      final vertices = <Point>[
        Point(50, 50),
        Point(50, 150),
        Point(150, 150),
        Point(150, 50),
        Point(100, 100),
      ];

      fillPolygon(i0, vertices: vertices, color: ColorRgb8(176, 0, 0));
      drawPolygon(i0, vertices: vertices, color: ColorRgb8(0, 255, 0));

      File('$testOutputPath/draw/fillPolygon2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      _expectPixels(
        i0,
        // Both arms beside the notch and the body below its tip.
        fill: [(55, 70), (145, 70), (100, 120), (75, 140), (125, 140)],
        // The V shaped notch stays unfilled, as does everything outside.
        background: [(100, 60), (100, 90), (80, 55), (20, 20), (100, 160)],
        outline: [
          ...vertices.map((p) => (p.xi, p.yi)),
          (50, 100),
          (100, 150),
          (150, 100),
          (75, 75),
          (125, 75),
        ],
      );
    });

    test('fillPolygon: interior pixel has fill color', () {
      // A simple axis-aligned square: the centroid must receive the fill color.
      final img = Image(width: 64, height: 64);
      final fillColor = ColorRgb8(200, 100, 50);
      fillPolygon(
        img,
        vertices: [
          Point(10, 10),
          Point(50, 10),
          Point(50, 50),
          Point(10, 50),
        ],
        color: fillColor,
      );
      // centroid at (30,30) is clearly inside the square
      final p = img.getPixel(30, 30);
      expect(p.r, equals(fillColor.r));
      expect(p.g, equals(fillColor.g));
      expect(p.b, equals(fillColor.b));
    });

    test('fillPolygon: pixel clearly outside polygon stays background', () {
      // Filling the small square must not affect the far corner.
      final img = Image(width: 64, height: 64);
      fillPolygon(
        img,
        vertices: [
          Point(10, 10),
          Point(30, 10),
          Point(30, 30),
          Point(10, 30),
        ],
        color: ColorRgb8(255, 0, 0),
      );
      // pixel at (63,63) is well outside the polygon
      final far = img.getPixel(63, 63);
      expect(far.r, equals(0));
      expect(far.g, equals(0));
      expect(far.b, equals(0));
    });

    test('fillPolygon: image dimensions unchanged', () {
      final img = Image(width: 64, height: 64);
      fillPolygon(
        img,
        vertices: [Point(5, 5), Point(30, 5), Point(30, 30), Point(5, 30)],
        color: ColorRgb8(0, 128, 0),
      );
      expect(img.width, equals(64));
      expect(img.height, equals(64));
    });
  });
}
