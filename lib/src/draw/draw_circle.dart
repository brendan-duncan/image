import '../image.dart';
import 'draw_pixel.dart';

/// Draw a circle into the [image] with a center of [x0],[y0] and
/// the given [radius] and [color].
Image drawCircle(Image image, int x0, int y0, int radius, int color) {
  if (radius < 0 ||
      x0 - radius >= image.width ||
      y0 + radius < 0 ||
      y0 - radius >= image.height) {
    return image;
  }

  if (radius == 0) {
    return drawPixel(image, x0, y0, color);
  }

  drawPixel(image, x0 - radius, y0, color);
  drawPixel(image, x0 + radius, y0, color);
  drawPixel(image, x0, y0 - radius, color);
  drawPixel(image, x0, y0 + radius, color);

  if (radius == 1) {
    return image;
  }

  for (int f = 1 - radius, ddFx = 0, ddFy = -(radius << 1), x = 0, y = radius;
      x < y;) {
    if (f >= 0) {
      f += (ddFy += 2);
      --y;
    }
    ++x;
    ddFx += 2;
    f += ddFx + 1;

    if (x != y + 1) {
      int x1 = x0 - y;
      int x2 = x0 + y;
      int y1 = y0 - x;
      int y2 = y0 + x;
      int x3 = x0 - x;
      int x4 = x0 + x;
      int y3 = y0 - y;
      int y4 = y0 + y;

      drawPixel(image, x1, y1, color);
      drawPixel(image, x1, y2, color);
      drawPixel(image, x2, y1, color);
      drawPixel(image, x2, y2, color);

      if (x != y) {
        drawPixel(image, x3, y3, color);
        drawPixel(image, x4, y4, color);
        drawPixel(image, x4, y3, color);
        drawPixel(image, x3, y4, color);
      }
    }
  }

  return image;
}
