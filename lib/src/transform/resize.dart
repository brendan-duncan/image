import 'dart:typed_data';

import '../color/color.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../image/pixel.dart';
import '../util/image_exception.dart';
import 'bake_orientation.dart';
import 'copy_resize.dart';

/// Resizes [src], reusing its storage where supported. Always use the returned
/// image: other formats or options may require a separate image. In-place
/// resizing mutates [src] and retains the original buffer capacity, so raw
/// getBytes() may include bytes beyond the resized logical pixel range.
Image resize(Image src,
    {int? width,
    int? height,
    bool? maintainAspect,
    Color? backgroundColor,
    Interpolation interpolation = Interpolation.nearest}) {
  if (width == null && height == null) {
    throw ImageException('Invalid size');
  }

  // You can't interpolate index pixels
  if (src.hasPalette) {
    interpolation = Interpolation.nearest;
  }

  if (src.exif.imageIfd.hasOrientation && src.exif.imageIfd.orientation != 1) {
    src = bakeOrientation(src);
  }

  var x1 = 0;
  var y1 = 0;
  var x2 = 0;
  var y2 = 0;

  // this block sets [width] and [height] if null or negative.
  if (width != null && height != null && maintainAspect == true) {
    x1 = 0;
    x2 = width;
    final srcAspect = src.height / src.width;
    final h = (width * srcAspect).toInt();
    final dy = (height - h) ~/ 2;
    y1 = dy;
    y2 = y1 + h;
    if (y1 < 0 || y2 > height) {
      y1 = 0;
      y2 = height;
      final srcAspect = src.width / src.height;
      final w = (height * srcAspect).toInt();
      final dx = (width - w) ~/ 2;
      x1 = dx;
      x2 = x1 + w;
    }
  } else {
    maintainAspect = false;
  }

  if (height == null || height <= 0) {
    height = (width! * (src.height / src.width)).round();
  }
  if (width == null || width <= 0) {
    width = (height * (src.width / src.height)).round();
  }

  final w = maintainAspect! ? x2 - x1 : width;
  final h = maintainAspect ? y2 - y1 : height;

  if (!maintainAspect) {
    x1 = 0;
    x2 = width;
    y1 = 0;
    y2 = height;
  }

  if (width == src.width && height == src.height) {
    return src;
  }

  // A repeated frame or shared ImageData must not be resized twice.
  final uniqueData = src.numFrames == 1 ||
      src.frames.map((f) => f.data).toSet().length == src.numFrames;
  final uint8Frames = uniqueData &&
      src.frames.every((f) =>
          f.format == Format.uint8 &&
          !f.hasPalette &&
          f.width == src.width &&
          f.height == src.height);
  final uint8Downscale = width > 0 &&
      height > 0 &&
      width <= src.width &&
      height <= src.height &&
      uint8Frames;
  final bufferedCubic = interpolation == Interpolation.cubic &&
      uint8Downscale &&
      (!maintainAspect ||
          (backgroundColor == null && w == width && h == height));
  final nearestBytes = interpolation == Interpolation.nearest &&
      uint8Frames &&
      src.frames.every((f) =>
          f.numChannels == 1 || f.numChannels == 3 || f.numChannels == 4);

  if (nearestBytes &&
      !maintainAspect &&
      width > 0 &&
      height > 0 &&
      (width > src.width || height > src.height) &&
      width * height <= src.width * src.height) {
    for (final frame in src.frames) {
      // Shrink one axis before expanding the other. Each axis is sampled
      // exactly once, preserving nearest's original coordinate mapping.
      _resizeNearestBuffer(frame, width < frame.width ? width : frame.width,
          height < frame.height ? height : frame.height);
      _resizeNearestBuffer(frame, width, height, reverse: true);
    }
    return src;
  }

  if (nearestBytes &&
      maintainAspect &&
      backgroundColor == null &&
      uint8Downscale &&
      w > 0 &&
      h > 0 &&
      (x1 != 0 || y1 != 0)) {
    for (final frame in src.frames) {
      _resizeNearestBuffer(frame, w, h);
      final bytes = frame.data!.toUint8List();
      final channels = frame.numChannels;
      // Expand the stride and apply the offset backwards. setRange handles
      // overlap inside a row; descending rows preserve not-yet-moved rows.
      for (var y = h - 1; y >= 0; y--) {
        final to = ((y1 + y) * width + x1) * channels;
        bytes.setRange(to, to + w * channels, bytes, y * w * channels);
      }
      // Match a newly allocated image's zero padding, after moving content.
      for (var y = 0; y < height; y++) {
        final row = y * width * channels;
        if (y < y1 || y >= y2) {
          bytes.fillRange(row, row + width * channels, 0);
        } else {
          bytes
            ..fillRange(row, row + x1 * channels, 0)
            ..fillRange(row + x2 * channels, row + width * channels, 0);
        }
      }
      frame.data!.width = width;
      frame.data!.height = height;
    }
    return src;
  }

  // Enlarging either axis can overwrite source pixels that are still needed,
  // even when the destination has the same or a smaller total pixel count.
  // Cubic also reads previous neighbors. Letterbox padding is unsupported
  // in place: offsets move writes ahead of unread source pixels, and clearing
  // the background would erase the source before it is sampled.
  if (width > src.width ||
      height > src.height ||
      (interpolation == Interpolation.cubic && !bufferedCubic) ||
      (maintainAspect && (x1 != 0 || y1 != 0 || w != width || h != height))) {
    return copyResize(src,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
        backgroundColor: backgroundColor,
        interpolation: interpolation);
  }

  if (uint8Downscale &&
      x1 == 0 &&
      y1 == 0 &&
      w == width &&
      h == height &&
      !(maintainAspect && backgroundColor != null) &&
      interpolation != Interpolation.cubic) {
    for (final frame in src.frames) {
      _resizeDownBytes(frame, width, height, interpolation);
    }
    return src;
  }

  final scaleX = Int32List(w);
  final dx = src.width / w;
  for (var x = 0; x < w; ++x) {
    scaleX[x] = (x * dx).toInt();
  }

  final origWidth = src.width;
  final origHeight = src.height;

  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = frame;

    final dy = frame.height / h;
    final dx = frame.width / w;

    if (maintainAspect && backgroundColor != null) {
      dst.clear(backgroundColor);
    }

    if (interpolation == Interpolation.average) {
      for (var y = 0; y < h; ++y) {
        final ay1 = (y * dy).toInt();
        var ay2 = ((y + 1) * dy).toInt();
        if (ay2 == ay1) {
          ay2++;
        }

        for (var x = 0; x < w; ++x) {
          final ax1 = (x * dx).toInt();
          var ax2 = ((x + 1) * dx).toInt();
          if (ax2 == ax1) {
            ax2++;
          }

          num r = 0;
          num g = 0;
          num b = 0;
          num a = 0;
          var np = 0;
          for (var sy = ay1; sy < ay2; ++sy) {
            for (var sx = ax1; sx < ax2; ++sx, ++np) {
              final s = frame.getPixel(sx, sy);
              r += s.r;
              g += s.g;
              b += s.b;
              a += s.a;
            }
          }
          final c = dst.getColor(r / np, g / np, b / np, a / np);

          dst.data!.width = width;
          dst.data!.height = height;
          dst.setPixel(x1 + x, y1 + y, c);
          dst.data!.width = origWidth;
          dst.data!.height = origHeight;
        }
      }
    } else if (interpolation == Interpolation.nearest) {
      if (frame.hasPalette) {
        for (var y = 0; y < h; ++y) {
          final y2 = (y * dy).toInt();
          for (var x = 0; x < w; ++x) {
            final p = frame.getPixelIndex(scaleX[x], y2);
            dst.data!.width = width;
            dst.data!.height = height;
            dst.setPixelIndex(x1 + x, y1 + y, p);
            dst.data!.width = origWidth;
            dst.data!.height = origHeight;
          }
        }
      } else {
        for (var y = 0; y < h; ++y) {
          final y2 = (y * dy).toInt();
          for (var x = 0; x < w; ++x) {
            final p = frame.getPixel(scaleX[x], y2);
            dst.data!.width = width;
            dst.data!.height = height;
            dst.setPixel(x1 + x, y1 + y, p);
            dst.data!.width = origWidth;
            dst.data!.height = origHeight;
          }
        }
      }
    } else {
      final rows = bufferedCubic ? _CubicRows(frame) : null;
      final sampler = rows ?? frame;
      for (var y = 0; y < h; ++y) {
        final sy2 = y * dy;
        rows?.prepare(sy2.toInt());
        for (var x = 0; x < w; ++x) {
          final sx2 = x * dx;
          final p = sampler.getPixelInterpolate(x1 + sx2, y1 + sy2,
              interpolation: interpolation);
          dst.data!.width = width;
          dst.data!.height = height;
          dst.setPixel(x, y, p);
          dst.data!.width = origWidth;
          dst.data!.height = origHeight;
        }
      }
    }

    dst.data!.width = width;
    dst.data!.height = height;
  }

  return src;
}

// Downscales a uint8 [frame] in place, computing the same values as the
// per-pixel paths of [resize]. Every source byte read is at or after every
// destination byte already written, so the source is never overwritten
// before it's read.
void _resizeDownBytes(
    Image frame, int width, int height, Interpolation interpolation) {
  final bytes = frame.data!.toUint8List();
  final nc = frame.numChannels;
  final sw = frame.width;
  final sh = frame.height;
  final dy = sh / height;
  final dx = sw / width;
  var di = 0;
  switch (interpolation) {
    case Interpolation.nearest:
      final sxs = Int32List(width);
      for (var x = 0; x < width; ++x) {
        sxs[x] = (x * dx).toInt() * nc;
      }
      for (var y = 0; y < height; ++y) {
        final row = (y * dy).toInt() * sw * nc;
        for (var x = 0; x < width; ++x) {
          final si = row + sxs[x];
          for (var c = 0; c < nc; ++c) {
            bytes[di++] = bytes[si + c];
          }
        }
      }
      break;
    case Interpolation.average:
      final sums = Int32List(nc);
      for (var y = 0; y < height; ++y) {
        final ay1 = (y * dy).toInt();
        var ay2 = ((y + 1) * dy).toInt();
        if (ay2 == ay1) {
          ay2++;
        }
        for (var x = 0; x < width; ++x) {
          final ax1 = (x * dx).toInt();
          var ax2 = ((x + 1) * dx).toInt();
          if (ax2 == ax1) {
            ax2++;
          }
          for (var c = 0; c < nc; ++c) {
            sums[c] = 0;
          }
          for (var sy = ay1; sy < ay2; ++sy) {
            for (var si = (sy * sw + ax1) * nc, se = (sy * sw + ax2) * nc;
                si < se;
                si += nc) {
              for (var c = 0; c < nc; ++c) {
                sums[c] += bytes[si + c];
              }
            }
          }
          final np = (ay2 - ay1) * (ax2 - ax1);
          for (var c = 0; c < nc; ++c) {
            // In [0, 255], so getColor's clamp does nothing.
            bytes[di++] = (sums[c] / np).toInt();
          }
        }
      }
      break;
    case Interpolation.linear:
      // As Image.getPixelLinear: taps past the right or bottom edge use the
      // center pixel.
      for (var y = 0; y < height; ++y) {
        final fy = y * dy;
        final iy = fy.toInt();
        final ky = fy - iy;
        final ny = iy + 1;
        final r0 = iy * sw;
        final r1 = ny * sw;
        for (var x = 0; x < width; ++x) {
          final fx = x * dx;
          final ix = fx.toInt();
          final kx = fx - ix;
          final nx = ix + 1;
          final cc = (r0 + ix) * nc;
          final cn = ny >= sh ? cc : (r1 + ix) * nc;
          final nc0 = nx >= sw ? cc : (r0 + nx) * nc;
          final nn = nx >= sw || ny >= sh ? cc : (r1 + nx) * nc;
          for (var c = 0; c < nc; ++c) {
            final icc = bytes[cc + c];
            final inc = bytes[nc0 + c];
            final icn = bytes[cn + c];
            final inn = bytes[nn + c];
            final v = icc +
                kx * (inc - icc + ky * (icc + inn - icn - inc)) +
                ky * (icn - icc);
            bytes[di++] = v < 0
                ? 0
                : v > 255
                    ? 255
                    : v.toInt();
          }
        }
      }
      break;
    case Interpolation.cubic:
      throw ImageException('cubic is not supported');
  }
  frame.data!.width = width;
  frame.data!.height = height;
}

// Internal callers shrink both axes forwards or expand both backwards,
// with enough existing buffer capacity for the destination.
void _resizeNearestBuffer(Image frame, int width, int height,
    {bool reverse = false}) {
  final bytes = frame.data!.toUint8List();
  final channels = frame.numChannels;
  final step = reverse ? -1 : 1;
  for (var y = reverse ? height - 1 : 0; y >= 0 && y < height; y += step) {
    final sy = (y * frame.height) ~/ height;
    for (var x = reverse ? width - 1 : 0; x >= 0 && x < width; x += step) {
      final sx = (x * frame.width) ~/ width;
      final to = (y * width + x) * channels;
      bytes.setRange(
          to, to + channels, bytes, (sy * frame.width + sx) * channels);
    }
  }
  frame.data!.width = width;
  frame.data!.height = height;
}

// Reuse Image's cubic arithmetic and bounds handling, replacing only reads.
// This relies on getPixelCubic -> getPixelSafe -> virtual getPixel dispatch.
// Direct data reads in that chain would bypass the cache and require adapting
// this sampler; immutable-source comparison tests protect that assumption.
// During downscaling, output row y ends before source row y + 1. Newly
// needed future rows are untouched; overlapping neighbors stay in the ring.
class _CubicRows extends Image {
  final Image _rows;
  final List<int> _tags = List.filled(4, -1);

  _CubicRows(Image source)
      : _rows = Image(
            width: source.width, height: 4, numChannels: source.numChannels),
        super.empty() {
    data = source.data;
  }

  void prepare(int centerY) {
    final stride = width * numChannels;
    final source = data!.toUint8List();
    final cached = _rows.data!.toUint8List();
    for (var y = centerY - 1; y <= centerY + 2; y++) {
      if (y < 0 || y >= height) continue;
      final slot = y % 4;
      if (_tags[slot] == y) continue;
      cached.setRange(slot * stride, (slot + 1) * stride, source, y * stride);
      _tags[slot] = y;
    }
  }

  @override
  Pixel getPixel(int x, int y, [Pixel? pixel]) =>
      _rows.getPixel(x, y % 4, pixel);
}
