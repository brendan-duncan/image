import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import 'draw_line.dart';

/// Draw a rectangle in the image [dst] with the [color].
Image drawRect(Image dst,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    num thickness = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final x0 = min(x1, x2);
  final y0 = min(y1, y2);
  x1 = max(x1, x2);
  y1 = max(y1, y2);

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
