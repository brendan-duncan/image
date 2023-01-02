import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import 'draw_pixel.dart';

/// Draw and fill a circle into the [image] with a center of [x],[y]
/// and the given [radius] and [color].
Image fillCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    bool antialias = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final radiusSqr = radius * radius;

  final x1 = max(0, x - radius);
  final y1 = max(0, y - radius);
  final x2 = min(image.width - 1, x + radius);
  final y2 = min(image.height - 1, y + radius);
  final range = image.getRange(x1, y1, (x2 - x1) + 1, (y2 - y1) + 1);
  while (range.moveNext()) {
    final p = range.current;
    if (antialias) {
      final dx1 = p.x - x;
      final dy1 = p.y - y;
      final d1 = dx1 * dx1 + dy1 * dy1;
      final dx2 = (p.x + 1) - x;
      final dy2 = p.y - y;
      final d2 = dx2 * dx2 + dy2 * dy2;
      final dx3 = (p.x + 1) - x;
      final dy3 = (p.y + 1) - y;
      final d3 = dx3 * dx3 + dy3 * dy3;
      final dx4 = p.x - x;
      final dy4 = (p.y + 1) - y;
      final d4 = dx4 * dx4 + dy4 * dy4;
      final r1 = d1 <= radiusSqr ? 1 : 0;
      final r2 = d2 <= radiusSqr ? 1 : 0;
      final r3 = d3 <= radiusSqr ? 1 : 0;
      final r4 = d4 <= radiusSqr ? 1 : 0;
      final a = r1 + r2 + r3 + r4;
      if (a > 0) {
        final alpha = color.aNormalized * (a / 4);
        drawPixel(image, p.x, p.y, color,
            alpha: alpha, mask: mask, maskChannel: maskChannel);
      }
    } else {
      final dx = p.x - x;
      final dy = p.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 < radiusSqr) {
        drawPixel(image, p.x, p.y, color, mask: mask, maskChannel: maskChannel);
      }
    }
  }

  /*final points = calculateCircumference(image, x, y, radius)
    // sort points by x-coordinate and then by y-coordinate
    ..sort((a, b) => (a.x == b.x) ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

  var start = points.first;
  var end = points.first;

  for (var pt in points.sublist(1)) {
    if (pt.x == start.x) {
      end = pt;
    } else {
      final x1 = min(start.xi, end.xi);
      final y1 = min(start.yi, end.yi);
      final x2 = max(start.xi, end.xi);
      final y2 = max(start.yi, end.yi);
      drawLine(image,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: color,
          mask: mask,
          maskChannel: maskChannel);
      start = pt;
      end = pt;
    }
  }

  final x1 = min(start.xi, end.xi);
  final y1 = min(start.yi, end.yi);
  final x2 = max(start.xi, end.xi);
  final y2 = max(start.yi, end.yi);
  drawLine(image,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      color: color,
      mask: mask,
      maskChannel: maskChannel);*/

  return image;
}
