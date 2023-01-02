import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '_calculate_circumference.dart';
import 'draw_pixel.dart';

/// Draw a circle into the [image] with a center of [x],[y] and
/// the given [radius] and [color].
Image drawCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    bool antialias = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (antialias) {
    void drawPixel4(int x, int y, int dx, int dy, num alpha) {
      drawPixel(image, x + dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x - dx, y + dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x + dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);

      drawPixel(image, x - dx, y - dy, color,
          alpha: alpha, mask: mask, maskChannel: maskChannel);
    }

    final radiusSqr = radius * radius;

    final quarter = (radius / sqrt2).round();
    for (var i = 0; i <= quarter; ++i) {
      final j = sqrt(radiusSqr - (i * i));
      final frc = fract(j);
      final frc2 = frc * ((i == quarter) ? 0.25 : 1);
      final flr = j.floor();
      drawPixel4(x, y, i, flr, 1 - frc);
      drawPixel4(x, y, i, flr + 1, frc2);
      drawPixel4(x, y, flr, i, 1 - frc);
      drawPixel4(x, y, flr + 1, i, frc2);
    }

    return image;
  }

  final points = calculateCircumference(image, x, y, radius);
  for (final pt in points) {
    drawPixel(image, pt.xi, pt.yi, color, mask: mask, maskChannel: maskChannel);
  }
  return image;
}
