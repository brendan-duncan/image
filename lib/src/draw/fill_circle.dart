import 'dart:math';

import '../../image.dart';
import '../util/_circle_test.dart';

/// Draw and fill a circle into the [image] with a center of [x],[y]
/// and the given [radius] and [color].
Image fillCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    bool antialias = false,
    BlendMode blend = BlendMode.alpha,
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
      final a = circleTest(p, x, y, radiusSqr, antialias: antialias);
      if (a > 0) {
        final alpha = color.aNormalized * a;
        drawPixel(image, p.x, p.y, color,
            alpha: alpha, blend: blend, mask: mask, maskChannel: maskChannel);
      }
    } else {
      final dx = p.x - x;
      final dy = p.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 < radiusSqr) {
        drawPixel(image, p.x, p.y, color,
            blend: blend, mask: mask, maskChannel: maskChannel);
      }
    }
  }

  return image;
}
