import 'dart:math';

import '../image.dart';
import '../util/clip_line.dart';
import 'draw_pixel.dart';

/// Draw a line into [image].
///
/// If [antialias] is true then the line is drawn with smooth edges.
/// [thickness] determines how thick the line should be drawn, in pixels.
Image drawLine(Image image, int x1, int y1, int x2, int y2, int color,
    {bool antialias = false, num thickness = 1}) {
  List<int> line = [x1, y1, x2, y2];
  if (!clipLine(line, [0, 0, image.width - 1, image.height - 1])) {
    return image;
  }

  x1 = line[0];
  y1 = line[1];
  x2 = line[2];
  y2 = line[3];

  int dx = (x2 - x1);
  int dy = (y2 - y1);

  // Drawing a single point.
  if (dx == 0 && dy == 0) {
    return drawPixel(image, x1, y1, color);
  }

  // Axis-aligned lines
  if (dx == 0) {
    if (dy < 0) {
      for (int y = y2; y <= y1; ++y) {
        drawPixel(image, x1, y, color);
      }
    } else {
      for (int y = y1; y <= y2; ++y) {
        drawPixel(image, x1, y, color);
      }
    }
    return image;
  } else if (dy == 0) {
    if (dx < 0) {
      for (int x = x2; x <= x1; ++x) {
        drawPixel(image, x, y1, color);
      }
    } else {
      for (int x = x1; x <= x2; ++x) {
        drawPixel(image, x, y1, color);
      }
    }
    return image;
  }

  // 16-bit unsigned int xor.
  int _xor(int n) => (~n + 0x10000) & 0xffff;

  if (!antialias) {
    dx = dx.abs();
    dy = dy.abs();
    if (dy <= dx) {
      // More-or-less horizontal. use wid for vertical stroke
      double ac = cos(atan2(dy, dx));
      int wid;
      if (ac != 0) {
        wid = thickness ~/ ac;
      } else {
        wid = 1;
      }

      if (wid == 0) {
        wid = 1;
      }

      int d = 2 * dy - dx;
      int incr1 = 2 * dy;
      int incr2 = 2 * (dy - dx);

      int x, y;
      int ydirflag;
      int xend;
      if (x1 > x2) {
        x = x2;
        y = y2;
        ydirflag = -1;
        xend = x1;
      } else {
        x = x1;
        y = y1;
        ydirflag = 1;
        xend = x2;
      }

      // Set up line thickness
      int wstart = (y - wid / 2).toInt();
      for (int w = wstart; w < wstart + wid; w++) {
        drawPixel(image, x, w, color);
      }

      if (((y2 - y1) * ydirflag) > 0) {
        while (x < xend) {
          x++;
          if (d < 0) {
            d += incr1;
          } else {
            y++;
            d += incr2;
          }
          wstart = (y - wid / 2).toInt();
          for (int w = wstart; w < wstart + wid; w++) {
            drawPixel(image, x, w, color);
          }
        }
      } else {
        while (x < xend) {
          x++;
          if (d < 0) {
            d += incr1;
          } else {
            y--;
            d += incr2;
          }
          wstart = (y - wid / 2).toInt();
          for (int w = wstart; w < wstart + wid; w++) {
            drawPixel(image, x, w, color);
          }
        }
      }
    } else {
      // More-or-less vertical. use wid for horizontal stroke
      double as = sin(atan2(dy, dx));
      int wid;
      if (as != 0) {
        wid = thickness ~/ as;
      } else {
        wid = 1;
      }
      if (wid == 0) {
        wid = 1;
      }

      int d = 2 * dx - dy;
      int incr1 = 2 * dx;
      int incr2 = 2 * (dx - dy);
      int x, y;
      int yend;
      int xdirflag;
      if (y1 > y2) {
        y = y2;
        x = x2;
        yend = y1;
        xdirflag = -1;
      } else {
        y = y1;
        x = x1;
        yend = y2;
        xdirflag = 1;
      }

      // Set up line thickness
      int wstart = (x - wid / 2).toInt();
      for (int w = wstart; w < wstart + wid; w++) {
        drawPixel(image, w, y, color);
      }

      if (((x2 - x1) * xdirflag) > 0) {
        while (y < yend) {
          y++;
          if (d < 0) {
            d += incr1;
          } else {
            x++;
            d += incr2;
          }
          wstart = (x - wid / 2).toInt();
          for (int w = wstart; w < wstart + wid; w++) {
            drawPixel(image, w, y, color);
          }
        }
      } else {
        while (y < yend) {
          y++;
          if (d < 0) {
            d += incr1;
          } else {
            x--;
            d += incr2;
          }
          wstart = (x - wid / 2).toInt();
          for (int w = wstart; w < wstart + wid; w++) {
            drawPixel(image, w, y, color);
          }
        }
      }
    }

    return image;
  }

  // Antialias Line

  double ag = (dy.abs() < dx.abs())
      ? cos(atan2(dy, dx))
      : sin(atan2(dy, dx));

  int wid;
  if (ag != 0.0) {
    wid = (thickness / ag).abs().toInt();
  } else {
    wid = 1;
  }
  if (wid == 0) {
    wid = 1;
  }

  if (dx.abs() > dy.abs()) {
    if (dx < 0) {
      int tmp = x1;
      x1 = x2;
      x2 = tmp;
      tmp = y1;
      y1 = y2;
      y2 = tmp;
      dx = x2 - x1;
      dy = y2 - y1;
    }

    int y = y1;
    int inc = (dy * 65536) ~/ dx;
    int frac = 0;

    for (int x = x1; x <= x2; x++) {
      int wstart = (y - wid ~/ 2);
      for (int w = wstart; w < wstart + wid; w++) {
        drawPixel(image, x, w, color, (frac >> 8) & 0xff);
        drawPixel(image, x, w + 1, color, (_xor(frac) >> 8) & 0xff);
      }

      frac += inc;
      if (frac >= 65536) {
        frac -= 65536;
        y++;
      } else if (frac < 0) {
        frac += 65536;
        y--;
      }
    }
  } else {
    if (dy < 0) {
      int tmp = x1;
      x1 = x2;
      x2 = tmp;
      tmp = y1;
      y1 = y2;
      y2 = tmp;
      dx = x2 - x1;
      dy = y2 - y1;
    }

    int x = x1;
    int inc = (dx * 65536) ~/ dy;
    int frac = 0;

    for (int y = y1; y <= y2; y++) {
      int wstart = (x - wid ~/ 2);
      for (int w = wstart; w < wstart + wid; w++) {
        drawPixel(image, w, y, color, (frac >> 8) & 0xff);
        drawPixel(image, w + 1, y, color, (_xor(frac) >> 8) & 0xff);
      }

      frac += inc;
      if (frac >= 65536) {
        frac -= 65536;
        x++;
      } else if (frac < 0) {
        frac += 65536;
        x--;
      }
    }
  }

  return image;
}
