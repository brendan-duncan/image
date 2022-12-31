import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '_calculate_circumference.dart';
import 'draw_line.dart';

/// Draw and fill a circle into the [image] with a center of [x],[y]
/// and the given [radius] and [color].
Image fillCircle(Image image,
    {required int x,
    required int y,
    required int radius,
    required Color color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final points = calculateCircumference(image, x, y, radius)
    // sort points by x-coordinate and then by y-coordinate
    ..sort((a, b) => (a.x == b.x) ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

  var start = points.first;
  var end = points.first;

  for (var pt in points.sublist(1)) {
    if (pt.x == start.x) {
      end = pt;
    } else {
      drawLine(image,
          x1: start.xi,
          y1: start.yi,
          x2: end.xi,
          y2: end.yi,
          color: color,
          mask: mask,
          maskChannel: maskChannel);
      start = pt;
      end = pt;
    }
  }
  drawLine(image,
      x1: start.xi,
      y1: start.yi,
      x2: end.xi,
      y2: end.yi,
      color: color,
      mask: mask,
      maskChannel: maskChannel);
  return image;
}
