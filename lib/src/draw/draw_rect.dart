import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '_calculate_circumference.dart';
import 'draw_line.dart';
import 'draw_pixel.dart';

/// Draw a rectangle in the image [dst] with the [color].
Image drawRect(Image dst,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    num thickness = 1,
    num radius = 0,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final x0 = min(x1, x2);
  final y0 = min(y1, y2);
  x1 = max(x1, x2);
  y1 = max(y1, y2);

  // Draw a rounded rectangle
  if (radius > 0) {
    final rad = radius.round();
    drawLine(dst, x1: x0 + rad, y1: y0, x2: x1 - rad, y2: y0, color: color);
    drawLine(dst, x1: x1, y1: y0 + rad, x2: x1, y2: y1 - rad, color: color);
    drawLine(dst, x1: x0 + rad, y1: y1, x2: x1 - rad, y2: y1, color: color);
    drawLine(dst, x1: x0, y1: y0 + rad, x2: x0, y2: y1 - rad, color: color);

    final points = calculateCircumference(dst, 0, 0, rad)
      ..sort((a, b) => (a.x == b.x) ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    final c1x = x0 + rad;
    final c1y = y0 + rad;
    final c2x = x1 - rad;
    final c2y = y0 + rad;
    final c3x = x1 - rad;
    final c3y = y1 - rad;
    final c4x = x0 + rad;
    final c4y = y1 - rad;

    for (final pt in points) {
      final x = pt.xi;
      final y = pt.yi;
      if (x < 0 && y < 0) {
        drawPixel(dst, c1x + x, c1y + y, color,
            mask: mask, maskChannel: maskChannel);
      }
      if (x > 0 && y < 0) {
        drawPixel(dst, c2x + x, c2y + y, color,
            mask: mask, maskChannel: maskChannel);
      }
      if (x > 0 && y > 0) {
        drawPixel(dst, c3x + x, c3y + y, color,
            mask: mask, maskChannel: maskChannel);
      }
      if (x < 0 && y > 0) {
        drawPixel(dst, c4x + x, c4y + y, color,
            mask: mask, maskChannel: maskChannel);
      }
    }
    return dst;
  }

  final ht = thickness / 2;

  drawLine(dst,
      x1: x0,
      y1: y0,
      x2: x1,
      y2: y0,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  drawLine(dst,
      x1: x0,
      y1: y1,
      x2: x1,
      y2: y1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  final isEvenThickness = (ht - ht.toInt()) == 0;
  final dh = isEvenThickness ? 1 : 0;

  final by0 = (y0 + ht).ceil();
  final by1 = ((y1 - ht) - dh).floor();
  final bx0 = (x0 + ht).floor();
  final bx1 = ((x1 - ht) + dh).ceil();

  drawLine(dst,
      x1: bx0,
      y1: by0,
      x2: bx0,
      y2: by1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  drawLine(dst,
      x1: bx1,
      y1: by0,
      x2: bx1,
      y2: by1,
      color: color,
      thickness: thickness,
      mask: mask,
      maskChannel: maskChannel);

  return dst;
}
