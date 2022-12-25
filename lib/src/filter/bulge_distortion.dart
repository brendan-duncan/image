import 'dart:math';

import '../image/image.dart';

/// Apply gamma scaling to the HDR image, in-place.
Image bulgeDistortion(Image src, { int? centerX, int? centerY,
    num? radius, num scale = 0.5 }) {
  for (final frame in src.frames) {
    final orig = frame.clone(noAnimation: true);
    final w = frame.width;
    final h = frame.height;
    final cx = centerX ?? w ~/ 2;
    final cy = centerY ?? h ~/ 2;
    final rad = radius ?? min(w, h) ~/ 2;
    final radSqr = rad * rad;
    for (final p in frame) {
      num x = p.x;
      num y = p.y;
      final deltaX = cx - x;
      final deltaY = cy - y;
      final dist = deltaX * deltaX + deltaY * deltaY;
      x -= cx;
      y -= cy;
      if (dist < radSqr) {
        final percent = 1 - ((radSqr - dist) / radSqr) * scale;
        final percentSqr = percent * percent;
        x *=  percentSqr;
        y *= percentSqr;
      }
      x += cx;
      y += cy;

      p.set(orig.getPixel(x.floor(), y.floor()));
    }
  }
  return src;
}
