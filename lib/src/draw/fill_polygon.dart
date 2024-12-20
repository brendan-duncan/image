import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../draw/draw_line.dart';
import '../draw/draw_pixel.dart';
import '../image/image.dart';
import '../util/point.dart';

/// Fill a polygon defined by the given [vertices].
Image fillPolygon(Image src,
    {required List<Point> vertices,
    required Color color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (color.a == 0) {
    return src;
  }

  final numVertices = vertices.length;

  if (numVertices == 0) {
    return src;
  }

  if (numVertices == 1) {
    return drawPixel(src, vertices[0].xi, vertices[0].yi, color,
        mask: mask, maskChannel: maskChannel);
  }

  if (numVertices == 2) {
    return drawLine(src,
        x1: vertices[0].xi,
        y1: vertices[0].yi,
        x2: vertices[1].xi,
        y2: vertices[1].yi,
        color: color,
        mask: mask,
        maskChannel: maskChannel);
  }

  var xMin = 0;
  var yMin = 0;
  var xMax = 0;
  var yMax = 0;
  var first = true;
  for (final vertex in vertices) {
    if (first) {
      xMin = vertex.xi;
      yMin = vertex.yi;
      xMax = vertex.xi;
      yMax = vertex.yi;
      first = false;
    } else {
      xMin = min(xMin, vertex.xi);
      yMin = min(yMin, vertex.yi);
      xMax = max(xMax, vertex.xi);
      yMax = max(yMax, vertex.yi);
    }
  }

  xMin = max(xMin, 0);
  yMin = max(yMin, 0);
  xMax = min(xMax, src.width - 1);
  yMax = min(yMax, src.height - 1);

  // Function to fill a complex polygon using the ray casting algorithm
  for (var yi = yMin, y = yMin + 0.5; yi <= yMax; ++yi, y += 1.0) {
    for (var xi = xMin, x = xMin + 0.5; xi <= xMax; ++xi, x += 1.0) {
      var intersections = 0;
      for (var vi = 0; vi < numVertices; ++vi) {
        final v1 = vertices[vi];
        final v2 = vertices[(vi + 1) % numVertices];
        // Ray casting: cast a ray to the right (x increasing)
        if (v1.y <= y && v2.y > y || v2.y <= y && v1.y > y) {
          // Ray intersects the edge (vertical check)
          final vt = (y - v1.y) / (v2.y - v1.y);
          if (x < v1.x + vt * (v2.x - v1.x)) { // Horizontal check
            intersections++;
          }
        }
      }
      // Even number of intersections means inside
      if (intersections & 0x1 == 1) {
        drawPixel(src, xi, yi, color, mask: mask, maskChannel: maskChannel);
      }
    }
  }

  return src;
}
