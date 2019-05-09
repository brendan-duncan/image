import '../color.dart';
import '../image.dart';
import '../transform/copy_into.dart';

/// Trim an image to the top-left and bottom-right most non-transparent pixels,
/// used by [findTrim] and [trim].
const int TRIM_TRANSPARENT = 0;

/// Trim an image to the top-left and bottom-right most pixels that are not the
/// same as the top-left most pixel of the image,
/// used by [findTrim] and [trim].
const int TRIM_TOP_LEFT_COLOR = 1;

/// Trim an image to the top-left and bottom-right most pixels that are not the
/// same as the bottom-right most pixel of the image,
/// used by [findTrim] and [trim].
const int TRIM_BOTTOM_RIGHT_COLOR = 2;

/// Trim the image down from the top,
/// used by [findTrim] and [trim].
const int TRIM_TOP = 1;

/// Trim the image up from the bottom,
/// used by [findTrim] and [trim].
const int TRIM_BOTTOM = 2;

/// Trim the left edge of the image,
/// used by [findTrim] and [trim].
const int TRIM_LEFT = 4;

/// Trim the right edge of the image,
/// used by [findTrim] and [trim].
const int TRIM_RIGHT = 8;

/// Trim all edges of the image,
/// used by [findTrim] and [trim].
const int TRIM_ALL = TRIM_TOP | TRIM_BOTTOM | TRIM_LEFT | TRIM_RIGHT;

/// Find the crop area to be used by the trim function. Returns the
/// coordinates as [x, y, width, height]. You could pass these coordinates
/// to the [copyCrop] function to crop the image.
List<int> findTrim(Image src, {int mode: TRIM_TRANSPARENT, int sides: TRIM_ALL}) {
  int h = src.height;
  int w = src.width;

  int bg = (mode == TRIM_TOP_LEFT_COLOR)
      ? src.getPixel(0, 0)
      : (mode == TRIM_BOTTOM_RIGHT_COLOR) ? src.getPixel(w - 1, h - 1) : 0;

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

  return [xmin, ymin, w, h];
}

/// Automatically crops the image by finding the corners of the image that
/// meet the [mode] criteria (not transparent or a different color).
///
/// [mode] can be either [TRIM_TRANSPARENT], [TRIM_TOP_LEFT_CORNER] or
/// [TRIM_BOTTOM_RIGHT_CORNER].
///
/// [sides] can be used to control which sides of the image get trimmed,
/// and can be any combination of [TRIM_TOP], [TRIM_BOTTOM], [TRIM_LEFT],
/// and [TRIM_RIGHT].
Image trim(Image src, {int mode: TRIM_TRANSPARENT, int sides: TRIM_ALL}) {
  if (mode == TRIM_TRANSPARENT && src.format == Image.RGB) {
    return new Image.from(src);
  }

  List<int> crop = findTrim(src, mode: mode, sides: sides);

  Image dst = Image(crop[2], crop[3], Image.RGBA, src.exif, src.iccProfile);
  copyInto(dst, src,
      srcX: crop[0], srcY: crop[1], srcW: crop[2], srcH: crop[3], blend: false);

  return dst;
}
