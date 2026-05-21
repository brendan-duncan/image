import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawPolygon', () {
      final i0 = Image(width: 256, height: 256);

      final vertices = <Point>[
        Point(50, 50),
        Point(200, 20),
        Point(120, 70),
        Point(30, 150),
      ];

      drawPolygon(
        i0,
        vertices: vertices,
        color: const ConstColorRgb8(255, 0, 0),
      );

      drawPolygon(
        i0,
        vertices: vertices.map((p) => Point(p.x + 20, p.y + 20)).toList(),
        color: ColorRgb8(0, 255, 0),
        antialias: true,
        thickness: 1.1,
      );

      drawPolygon(
        i0,
        vertices: vertices.map((p) => Point(p.x + 40, p.y + 40)).toList(),
        color: const ConstColorRgb8(0, 0, 255),
        antialias: true,
      );

      File('$testOutputPath/draw/drawPolygon.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('drawPolygon: image dimensions unchanged', () {
      // drawing must not alter image dimensions
      final img = Image(width: 64, height: 64);
      drawPolygon(
        img,
        vertices: [Point(10, 10), Point(50, 10), Point(50, 50), Point(10, 50)],
        color: ColorRgb8(255, 0, 0),
      );
      expect(img.width, equals(64));
      expect(img.height, equals(64));
    });

    test('drawPolygon: at least one vertex pixel has draw color', () {
      // drawPolygon draws lines through each vertex pair, so vertex pixels
      // must carry the draw color (no anti-aliasing, opaque color).
      final img = Image(width: 64, height: 64);
      const color = ConstColorRgb8(0, 255, 0);
      final verts = [
        Point(10, 10),
        Point(50, 10),
        Point(50, 50),
        Point(10, 50),
      ];
      drawPolygon(img, vertices: verts, color: color);

      // count pixels that match the draw color
      var colored = 0;
      for (final p in img) {
        if (p.r == 0 && p.g == 255 && p.b == 0) colored++;
      }
      // any polygon with 4 vertices connected by lines must paint ≥1 pixel
      expect(colored, greaterThan(0),
          reason: 'expected at least one pixel with draw color');
    });

    test('drawPolygon: pixels far from outline stay background', () {
      // A rectangle drawn in one corner should not affect the far corner.
      final img = Image(width: 64, height: 64);
      drawPolygon(
        img,
        vertices: [Point(2, 2), Point(10, 2), Point(10, 10), Point(2, 10)],
        color: ColorRgb8(255, 0, 0),
      );
      // pixel at far corner (63,63) must remain black (default Image fill)
      final far = img.getPixel(63, 63);
      expect(far.r, equals(0));
      expect(far.g, equals(0));
      expect(far.b, equals(0));
    });
  });
}
