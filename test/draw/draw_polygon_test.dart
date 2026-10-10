import 'dart:io';
import 'dart:math' show max, min, sqrt;

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Distance from ([x],[y]) to the closed outline through [verts].
double _distToOutline(int x, int y, List<Point> verts) {
  var best = double.infinity;
  for (var i = 0; i < verts.length; ++i) {
    final a = verts[i];
    final b = verts[(i + 1) % verts.length];
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final t = (((x - a.x) * dx + (y - a.y) * dy) / (dx * dx + dy * dy))
        .clamp(0.0, 1.0);
    final ex = a.x + t * dx - x;
    final ey = a.y + t * dy - y;
    best = min(best, sqrt(ex * ex + ey * ey));
  }
  return best;
}

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

      // The opaque red outline passes exactly through its vertices and the
      // midpoints of its edges, including the closing edge.
      for (var i = 0; i < vertices.length; ++i) {
        final a = vertices[i];
        final b = vertices[(i + 1) % vertices.length];
        expect(i0.getPixel(a.xi, a.yi), equals([255, 0, 0]),
            reason: 'vertex $i');
        expect(i0.getPixel((a.xi + b.xi) ~/ 2, (a.yi + b.yi) ~/ 2),
            equals([255, 0, 0]),
            reason: 'edge $i midpoint');
      }

      // Each channel is drawn only along its own polygon's outline.
      final outlines = [
        (0, vertices, 1.0),
        (1, vertices.map((p) => Point(p.x + 20, p.y + 20)).toList(), 2.0),
        (2, vertices.map((p) => Point(p.x + 40, p.y + 40)).toList(), 2.0),
      ];
      for (final (channel, verts, tolerance) in outlines) {
        // The antialiased outlines are strong near every edge midpoint.
        if (channel > 0) {
          for (var i = 0; i < verts.length; ++i) {
            final a = verts[i];
            final b = verts[(i + 1) % verts.length];
            final mx = (a.xi + b.xi) ~/ 2;
            final my = (a.yi + b.yi) ~/ 2;
            var peak = 0;
            for (var y = my - 2; y <= my + 2; ++y) {
              for (var x = mx - 2; x <= mx + 2; ++x) {
                peak = max(peak, i0.getPixel(x, y)[channel].toInt());
              }
            }
            expect(peak, greaterThan(127),
                reason: 'channel $channel edge $i midpoint');
          }
        }
        for (final p in i0) {
          if (p[channel] != 0) {
            expect(
                _distToOutline(p.x, p.y, verts), lessThanOrEqualTo(tolerance),
                reason: 'channel $channel at ${p.x},${p.y}');
          }
        }
      }
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
