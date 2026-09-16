import 'dart:typed_data';

import '../color/color.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../image/pixel.dart';
import '../util/image_exception.dart';
import 'bake_orientation.dart';
import 'copy_resize.dart';

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

  final uint8Downscale = width > 0 &&
      height > 0 &&
      width <= src.width &&
      height <= src.height &&
      src.frames.every((f) =>
          f.format == Format.uint8 &&
          !f.hasPalette &&
          f.width == src.width &&
          f.height == src.height);
  final bufferedCubic =
      interpolation == Interpolation.cubic && !maintainAspect && uint8Downscale;

  if (interpolation == Interpolation.nearest &&
      maintainAspect &&
      backgroundColor == null &&
      uint8Downscale &&
      src.frames.every((f) => f.numChannels == 3 || f.numChannels == 4) &&
      w > 0 &&
      h > 0 &&
      (x1 != 0 || y1 != 0)) {
    for (final frame in src.frames) {
      final bytes = frame.data!.toUint8List();
      final channels = frame.numChannels;
      // Compact without offsets first: each write is behind future reads.
      for (var y = 0; y < h; y++) {
        final sy = (y * frame.height) ~/ h;
        for (var x = 0; x < w; x++) {
          final sx = (x * frame.width) ~/ w;
          final to = (y * w + x) * channels;
          bytes.setRange(
              to, to + channels, bytes, (sy * frame.width + sx) * channels);
        }
      }
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
  // Cubic also reads previous neighbours, and letterbox offsets can move
  // nearest-neighbour writes ahead of unread source pixels.
  if (width > src.width ||
      height > src.height ||
      (interpolation == Interpolation.cubic && !bufferedCubic) ||
      (interpolation == Interpolation.nearest && (x1 != 0 || y1 != 0))) {
    return copyResize(src,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
        backgroundColor: backgroundColor,
        interpolation: interpolation);
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

// Reuse Image's cubic arithmetic and bounds handling, replacing only reads.
// During downscaling, output row y ends before source row y + 1. Newly
// needed future rows are untouched; overlapping neighbours stay in the ring.
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
