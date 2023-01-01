import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';
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
  const antialias = true;
  if (antialias) {
    void drawPixel4(int x, int y, int dx, int dy, num alpha) {
      alpha *= color.aNormalized;
      drawPixel(image, x + dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x - dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x - dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x + dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }

    final quarter = (radius / sqrt2).round();
    for (var i = 0; i < quarter; ++i) {
      final j = sqrt(radiusSqr - (i * i));
      final frc = fract(j);
      final flr = j.floor();
      drawPixel4(x, y, i, flr, 1 - frc);
      drawPixel4(x, y, i, flr + 1, frc);
      drawPixel4(x, y, flr, i, 1 - frc);
      drawPixel4(x, y, flr + 1, i, frc);
    }
  }

  final x1 = max(0, x - radius);
  final y1 = max(0, y - radius);
  final x2 = min(image.width - 1, x + radius);
  final y2 = min(image.height - 1, y + radius);
  final range = image.getRange(x1, y1, (x2 - x1) + 1, (y2 - y1) + 1);
  while (range.moveNext()) {
    final p = range.current;
    final dx = p.x - x;
    final dy = p.y - y;
    final d2 = sqrt(dx * dx + dy * dy);
    if (d2 < radius) {
      drawPixel(image, p.x, p.y, color, mask: mask, maskChannel: maskChannel);
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
