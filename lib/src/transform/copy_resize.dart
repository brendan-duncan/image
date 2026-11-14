import 'dart:typed_data';

import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/_alpha_weight.dart';
import '../util/_linear_rgb.dart';
import '../util/image_exception.dart';
import '_resize_bytes.dart';
import 'bake_orientation.dart';

double _linear(
        double icc, double inc, double icn, double inn, double kx, double ky) =>
    icc + kx * (inc - icc + ky * (icc + inn - icn - inc)) + ky * (icn - icc);

/// Returns a resized copy of the [src] Image.
/// If [height] isn't specified, then it will be determined by the aspect
/// ratio of [src] and [width].
/// If [width] isn't specified, then it will be determined by the aspect ratio
/// of [src] and [height].
///
/// If [linearBlend] is true, the colors, taken as sRGB, are blended as linear
/// light, which is slower but keeps fine bright details, such as text or
/// highlights, from darkening as the image shrinks. It has no effect with
/// [Interpolation.nearest].
///
/// [Interpolation.linear], [Interpolation.cubic] and [Interpolation.average]
/// weight color by alpha where blended pixels have different alpha, so color
/// of fully transparent pixels has no effect on visible pixels
Image copyResize(Image src,
    {int? width,
    int? height,
    bool? maintainAspect,
    Color? backgroundColor,
    Interpolation interpolation = Interpolation.nearest,
    bool linearBlend = false}) {
  if (width == null && height == null) {
    throw ImageException('Invalid size');
  }

  if (linearBlend &&
      interpolation != Interpolation.nearest &&
      !src.hasPalette) {
    return srgbCopy(
        copyResize(linearRgbCopy(src),
            width: width,
            height: height,
            maintainAspect: maintainAspect,
            backgroundColor: linearColor(backgroundColor),
            interpolation: interpolation),
        src.format);
  }

  // You can't interpolate index pixels
  if (src.hasPalette) {
    interpolation = Interpolation.nearest;
  }

  // An EXIF orientation is applied while resizing when the byte fast paths
  // support the image, rather than first baking it into a rotated copy.
  var orientation = 1;
  if (src.exif.imageIfd.hasOrientation && src.exif.imageIfd.orientation != 1) {
    final o = src.exif.imageIfd.orientation!;
    if (o >= 2 &&
        o <= 8 &&
        src.frames.every((f) => canResizeBytes(f, interpolation))) {
      orientation = o;
    } else {
      src = bakeOrientation(src);
    }
  }
  final srcWidth = orientedWidth(src, orientation);
  final srcHeight = orientedHeight(src, orientation);

  var x1 = 0;
  var y1 = 0;
  var x2 = 0;
  var y2 = 0;

  // this block sets [width] and [height] if null or negative.
  if (width != null && height != null && maintainAspect == true) {
    x1 = 0;
    x2 = width;
    final srcAspect = srcHeight / srcWidth;
    final h = (width * srcAspect).toInt();
    final dy = (height - h) ~/ 2;
    y1 = dy;
    y2 = y1 + h;
    if (y1 < 0 || y2 > height) {
      y1 = 0;
      y2 = height;
      final srcAspect = srcWidth / srcHeight;
      final w = (height * srcAspect).toInt();
      final dx = (width - w) ~/ 2;
      x1 = dx;
      x2 = x1 + w;
    }
  } else {
    maintainAspect = false;
  }

  if (height == null || height <= 0) {
    height = (width! * (srcHeight / srcWidth)).round();
  }
  if (width == null || width <= 0) {
    width = (height * (srcWidth / srcHeight)).round();
  }

  final w = maintainAspect! ? x2 - x1 : width;
  final h = maintainAspect ? y2 - y1 : height;

  if (!maintainAspect) {
    x1 = 0;
    x2 = width;
    y1 = 0;
    y2 = height;
  }

  if (width == srcWidth && height == srcHeight) {
    return orientation == 1 ? src.clone() : bakeOrientation(src);
  }

  final scaleX = Int32List(w);
  for (var x = 0; x < w; ++x) {
    scaleX[x] = (x * srcWidth) ~/ w;
  }
  final scaleY = Int32List(h);
  for (var y = 0; y < h; ++y) {
    scaleY[y] = (y * srcHeight) ~/ h;
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  final noOffset = x1 == 0 && y1 == 0;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = Image.fromResized(frame,
        width: width, height: height, noAnimation: true);
    firstFrame?.addFrame(dst);
    firstFrame ??= dst;

    final dy = orientedHeight(frame, orientation) / h;
    final dx = orientedWidth(frame, orientation) / w;

    if (maintainAspect && backgroundColor != null) {
      dst.clear(backgroundColor);
    }

    if (resizeBytes(
        frame, dst, interpolation, x1, y1, w, h, dx, dy, scaleX, scaleY,
        orientation: orientation)) {
      continue;
    }
    // Orientation is only folded in when the fast paths support the image.
    assert(orientation == 1);

    if (interpolation == Interpolation.average) {
      final srcPixel = frame.getPixelSafe(0, 0);
      final hasAlpha = frame.hasAlpha;
      for (var y = 0; y < h; ++y) {
        final ay1 = (y * dy).toInt();
        var ay2 = ((y + 1) * dy).toInt();
        if (ay2 == ay1) {
          ay2++;
        }
        final dstY = y1 + y;

        for (var x = 0; x < w; ++x) {
          final ax1 = (x * dx).toInt();
          var ax2 = ((x + 1) * dx).toInt();
          if (ax2 == ax1) {
            ax2++;
          }

          var r = 0.0;
          var g = 0.0;
          var b = 0.0;
          var a = 0.0;
          var np = 0;
          var weightedRed = 0.0;
          var weightedGreen = 0.0;
          var weightedBlue = 0.0;
          var firstAlpha = 0.0;
          var isMixed = false;
          var hasNegativeAlpha = false;

          for (var sy = ay1; sy < ay2; ++sy) {
            for (var sx = ax1; sx < ax2; ++sx, ++np) {
              frame.getPixel(sx, sy, srcPixel);
              final pixelRed = srcPixel.r.toDouble();
              final pixelGreen = srcPixel.g.toDouble();
              final pixelBlue = srcPixel.b.toDouble();
              final pixelAlpha = srcPixel.a.toDouble();

              // Weighted sums start at first pixel with different alpha:
              // until then they equal plain sums times firstAlpha, and adding
              // them for every block cost 4% on uint16 and 15% on float32
              if (isMixed) {
                weightedRed += pixelRed * pixelAlpha;
                weightedGreen += pixelGreen * pixelAlpha;
                weightedBlue += pixelBlue * pixelAlpha;
              } else if (np == 0) {
                firstAlpha = pixelAlpha;
              } else if (hasAlpha && pixelAlpha != firstAlpha) {
                isMixed = true;
                weightedRed = r * firstAlpha + pixelRed * pixelAlpha;
                weightedGreen = g * firstAlpha + pixelGreen * pixelAlpha;
                weightedBlue = b * firstAlpha + pixelBlue * pixelAlpha;
              }

              hasNegativeAlpha = hasNegativeAlpha || pixelAlpha < 0;
              r += pixelRed;
              g += pixelGreen;
              b += pixelBlue;
              a += pixelAlpha;
            }
          }

          // Negative alpha in signed or float format can make alpha sum 0
          // and color NaN, so only block with non-negative mixed alpha is
          // weighted as in AlphaBlockSums
          if (isMixed && !hasNegativeAlpha) {
            dst.setPixelRgba(x1 + x, dstY, weightedRed / a, weightedGreen / a,
                weightedBlue / a, a / np);
            continue;
          }

          // Multiplying by 1 / np gave 199 for solid 200 in 7x7 blocks
          dst.setPixelRgba(x1 + x, dstY, r / np, g / np, b / np, a / np);
        }
      }
    } else if (interpolation == Interpolation.nearest) {
      if (frame.hasPalette) {
        for (var y = 0; y < h; ++y) {
          final y2 = scaleY[y];
          final dstY = y1 + y;
          for (var x = 0; x < w; ++x) {
            dst.setPixelIndex(x1 + x, dstY, frame.getPixelIndex(scaleX[x], y2));
          }
        }
      } else if (noOffset) {
        final srcPixel = frame.getPixelSafe(0, 0);
        for (var y = 0; y < h; ++y) {
          final sy = scaleY[y];
          for (var x = 0; x < w; ++x) {
            frame.getPixel(scaleX[x], sy, srcPixel);
            dst.setPixelRgba(
                x, y, srcPixel.r, srcPixel.g, srcPixel.b, srcPixel.a);
          }
        }
      } else {
        final srcPixel = frame.getPixelSafe(0, 0);
        for (var y = 0; y < h; ++y) {
          final sy = scaleY[y];
          final dstY = y1 + y;
          for (var x = 0; x < w; ++x) {
            frame.getPixel(scaleX[x], sy, srcPixel);
            dst.setPixelRgba(
                x1 + x, dstY, srcPixel.r, srcPixel.g, srcPixel.b, srcPixel.a);
          }
        }
      }
    } else if (interpolation == Interpolation.linear) {
      final icc = frame.getPixelSafe(0, 0);
      final icn = frame.getPixelSafe(0, 0);
      final inc = frame.getPixelSafe(0, 0);
      final inn = frame.getPixelSafe(0, 0);
      final maxX = frame.width - 1;
      final maxY = frame.height - 1;

      for (var y = 0; y < h; ++y) {
        final fy = y * dy;
        final iy = fy.toInt();
        final ky = fy - iy;
        final ny = (iy + 1).clamp(0, maxY);
        final dstY = y1 + y;
        for (var x = 0; x < w; ++x) {
          final fx = x * dx;
          final ix = fx.toInt();
          final kx = fx - ix;
          final nx = (ix + 1).clamp(0, maxX);

          frame
            ..getPixel(ix, iy, icc)
            ..getPixel(ix, ny, icn)
            ..getPixel(nx, iy, inc)
            ..getPixel(nx, ny, inn);

          final centerAlpha = icc.a.toDouble();
          final rightAlpha = inc.a.toDouble();
          final belowAlpha = icn.a.toDouble();
          final diagonalAlpha = inn.a.toDouble();
          final alpha = _linear(
              centerAlpha, rightAlpha, belowAlpha, diagonalAlpha, kx, ky);
          final isMixed = centerAlpha != rightAlpha ||
              centerAlpha != belowAlpha ||
              centerAlpha != diagonalAlpha;

          // Plain blend mixes RGB of transparent taps into visible ones, so
          // taps with different alpha are weighted by alpha
          if (isMixed && alpha > 0) {
            dst.setPixelRgba(
                x1 + x,
                dstY,
                alphaWeightedLinear(
                    icc.r.toDouble(),
                    inc.r.toDouble(),
                    icn.r.toDouble(),
                    inn.r.toDouble(),
                    centerAlpha,
                    rightAlpha,
                    belowAlpha,
                    diagonalAlpha,
                    kx,
                    ky,
                    alpha),
                alphaWeightedLinear(
                    icc.g.toDouble(),
                    inc.g.toDouble(),
                    icn.g.toDouble(),
                    inn.g.toDouble(),
                    centerAlpha,
                    rightAlpha,
                    belowAlpha,
                    diagonalAlpha,
                    kx,
                    ky,
                    alpha),
                alphaWeightedLinear(
                    icc.b.toDouble(),
                    inc.b.toDouble(),
                    icn.b.toDouble(),
                    inn.b.toDouble(),
                    centerAlpha,
                    rightAlpha,
                    belowAlpha,
                    diagonalAlpha,
                    kx,
                    ky,
                    alpha),
                alpha);
            continue;
          }

          dst.setPixelRgba(
              x1 + x,
              dstY,
              _linear(icc.r.toDouble(), inc.r.toDouble(), icn.r.toDouble(),
                  inn.r.toDouble(), kx, ky),
              _linear(icc.g.toDouble(), inc.g.toDouble(), icn.g.toDouble(),
                  inn.g.toDouble(), kx, ky),
              _linear(icc.b.toDouble(), inc.b.toDouble(), icn.b.toDouble(),
                  inn.b.toDouble(), kx, ky),
              alpha);
        }
      }
    } else {
      for (var y = 0; y < h; ++y) {
        final sy2 = y * dy;
        final dstY = y1 + y;
        for (var x = 0; x < w; ++x) {
          final sx2 = x * dx;
          dst.setPixel(
              x1 + x,
              dstY,
              frame.getPixelInterpolate(sx2, sy2,
                  interpolation: interpolation));
        }
      }
    }
  }

  if (orientation != 1) {
    // As bakeOrientation does.
    firstFrame!.exif.imageIfd.orientation = null;
  }

  return firstFrame!;
}
