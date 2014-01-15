part of image;

const int TRIM_TRANSPARENT = 0;
const int TRIM_TOP_LEFT_COLOR = 1;
const int TRIM_BOTTOM_RIGHT_COLOR = 2;

const int TRIM_TOP = 1;
const int TRIM_BOTTOM = 2;
const int TRIM_LEFT = 4;
const int TRIM_RIGHT = 8;
const int TRIM_ALL = TRIM_TOP | TRIM_BOTTOM | TRIM_LEFT | TRIM_RIGHT;

/**
 * Automatically crops the image by finding the corners of the image that
 * meet the [mode] criteria (not transparent or a different color).
 *
 * [mode] can be either [TRIM_TRANSPARENT], [TRIM_TOP_LEFT_CORNER] or
 * [TRIM_BOTTOM_RIGHT_CORNER].
 *
 * [sides] can be used to control which sides of the image get trimmed,
 * and can be any combination of [TRIM_TOP], [TRIM_BOTTOM], [TRIM_LEFT],
 * and [TRIM_RIGHT].
 */
Image trim(Image src, {int mode: TRIM_TRANSPARENT, sides: TRIM_ALL}) {
  if (mode == TRIM_TRANSPARENT && src.format == Image.RGB) {
    return new Image.from(src);
  }

  int h = src.height;
  int w = src.width;

  int bg = (mode == TRIM_TOP_LEFT_COLOR) ? src.getPixel(0, 0) :
           (mode == TRIM_BOTTOM_RIGHT_COLOR) ? src.getPixel(w - 1, h - 1) :
           0;

  int xmin = w;
  int xmax = 0;
  int ymin;
  int ymax = 0;

  for (int y = 0; y < h; ++y) {
    bool first = true;
    for (int x = 0; x < w; ++x) {
      int c = src.getPixel(x, y);
      if ((mode == TRIM_TRANSPARENT && getAlpha(c) != 0) && (c != bg)) {
        if (xmin > x) {
          xmin = x;
        }
        if (xmax < x) {
          xmax = x;
        }
        if (ymin == null) {
          ymin = y;
        }

        ymax = y;

        if (first) {
          x = xmax;
          first = false;
        }
      }
    }
  }

  if (sides & TRIM_TOP == 0) {
    ymin = 0;
  }
  if (sides & TRIM_BOTTOM == 0) {
    ymax = h - 1;
  }
  if (sides & TRIM_LEFT == 0) {
    xmin = 0;
  }
  if (sides & TRIM_RIGHT == 0) {
    xmax = w - 1;
  }

  w = 1 + xmax - xmin; // Image width in pixels
  h = 1 + ymax - ymin; // Image height in pixels

  Image dst = new Image(w, h, Image.RGBA);
  copyInto(dst, src, srcX: xmin, srcY: ymin, srcW: w, srcH: h, blend: false);

  return dst;
}
