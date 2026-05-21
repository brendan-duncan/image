import '../draw/blend_mode.dart';
import '../draw/composite_image.dart';
import '../image/image.dart';

class Trim {
  /// Trim the image down from the top.
  static const top = Trim._internal(1);

  /// Trim the image up from the bottom.
  static const bottom = Trim._internal(2);

  /// Trim the left edge of the image.
  static const left = Trim._internal(4);

  /// Trim the right edge of the image.
  static const right = Trim._internal(8);

  /// Trim all edges of the image.
  static const all = Trim._internal(1 | 2 | 4 | 8);

  final int _value;
  const Trim._internal(this._value);

  Trim operator |(Trim rhs) => Trim._internal(_value | rhs._value);
  bool operator &(Trim rhs) => (_value & rhs._value) != 0;
}

enum TrimMode {
  /// Trim an image to the top-left and bottom-right most non-transparent pixels
  transparent,

  /// Trim an image to the top-left and bottom-right most pixels that are not
  /// the same as the top-left most pixel of the image.
  topLeftColor,

  /// Trim an image to the top-left and bottom-right most pixels that are not
  /// the same as the bottom-right most pixel of the image.
  bottomRightColor
}

/// Find the crop area to be used by the trim function. Returns the
/// coordinates as \[x, y, width, height\]. You could pass these coordinates
/// to the copyCrop function to crop the image.
///
/// [fuzzy] (0..1) allows colors close to the background color to also be
/// trimmed, which is useful for images with compression artifacts. It is
/// ignored for [TrimMode.transparent].
///
/// [padding] keeps a border of that many pixels around the trimmed area,
/// clamped to the bounds of the image.
List<int> findTrim(Image src,
    {TrimMode mode = TrimMode.transparent,
    Trim sides = Trim.all,
    num fuzzy = 0,
    int padding = 0}) {
  var h = src.height;
  var w = src.width;

  final bg = (mode == TrimMode.topLeftColor)
      ? src.getPixel(0, 0)
      : (mode == TrimMode.bottomRightColor)
          ? src.getPixel(w - 1, h - 1)
          : null;

  var xMin = w;
  var xMax = 0;
  int? yMin;
  var yMax = 0;

  for (var y = 0; y < h; ++y) {
    var first = true;
    for (var x = 0; x < w; ++x) {
      final c = src.getPixel(x, y);
      final bool isContent;
      if (mode == TrimMode.transparent) {
        isContent = c.a != 0;
      } else if (fuzzy <= 0) {
        isContent = c != bg;
      } else {
        final bgp = bg!;
        isContent = (c.rNormalized - bgp.rNormalized).abs() > fuzzy ||
            (c.gNormalized - bgp.gNormalized).abs() > fuzzy ||
            (c.bNormalized - bgp.bNormalized).abs() > fuzzy ||
            (c.aNormalized - bgp.aNormalized).abs() > fuzzy;
      }
      if (isContent) {
        if (xMin > x) {
          xMin = x;
        }
        if (xMax < x) {
          xMax = x;
        }
        yMin ??= y;

        yMax = y;

        if (first) {
          x = xMax;
          first = false;
        }
      }
    }
  }

  // A trim wasn't found
  if (yMin == null) {
    return [0, 0, w, h];
  }

  if (sides & Trim.top == false) {
    yMin = 0;
  }
  if (sides & Trim.bottom == false) {
    yMax = h - 1;
  }
  if (sides & Trim.left == false) {
    xMin = 0;
  }
  if (sides & Trim.right == false) {
    xMax = w - 1;
  }

  if (padding > 0) {
    xMin = (xMin - padding).clamp(0, w - 1);
    yMin = (yMin - padding).clamp(0, h - 1);
    xMax = (xMax + padding).clamp(0, w - 1);
    yMax = (yMax + padding).clamp(0, h - 1);
  }

  w = 1 + xMax - xMin; // Image width in pixels
  h = 1 + yMax - yMin; // Image height in pixels

  return [xMin, yMin, w, h];
}

/// Automatically crops the image by finding the corners of the image that
/// meet the [mode] criteria (not transparent or a different color).
///
/// [mode] can be either [TrimMode.transparent], [TrimMode.topLeftColor] or
/// [TrimMode.bottomRightColor].
///
/// [sides] can be used to control which sides of the image get trimmed,
/// and can be any combination of [Trim.top], [Trim.bottom], [Trim.left],
/// and [Trim.right].
///
/// [fuzzy] (0..1) trims colors close to the background color, which helps
/// with compression artifacts. [padding] keeps a border of that many pixels
/// around the trimmed result.
Image trim(Image src,
    {TrimMode mode = TrimMode.topLeftColor,
    Trim sides = Trim.all,
    num fuzzy = 0,
    int padding = 0}) {
  if (mode == TrimMode.transparent && src.numChannels == 3) {
    return Image.from(src);
  }

  final crop =
      findTrim(src, mode: mode, sides: sides, fuzzy: fuzzy, padding: padding);

  Image? firstFrame;
  for (var frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame,
            width: crop[2], height: crop[3], noAnimation: true);
    firstFrame ??= dst;

    compositeImage(dst, src,
        srcX: crop[0],
        srcY: crop[1],
        srcW: crop[2],
        srcH: crop[3],
        blend: BlendMode.direct);
  }

  return firstFrame!;
}
