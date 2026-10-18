import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/_linear_rgb.dart';
import '../util/point.dart';

/// Returns a copy of the [src] image, where the given rectangle
/// has been mapped to the full image.
///
/// If [linearBlend] is true, the colors, taken as sRGB, are interpolated as
/// linear light, which is slower but keeps fine bright details from
/// darkening. It has no effect with [Interpolation.nearest].
Image copyRectify(Image src,
    {required Point topLeft,
    required Point topRight,
    required Point bottomLeft,
    required Point bottomRight,
    Interpolation interpolation = Interpolation.nearest,
    Image? toImage,
    bool linearBlend = false}) {
  if (linearBlend &&
      interpolation != Interpolation.nearest &&
      toImage?.hasPalette != true) {
    final linear = copyRectify(linearRgbCopy(src),
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        interpolation: interpolation,
        toImage:
            toImage != null ? linearRgbCopy(toImage, noAnimation: true) : null);
    if (toImage == null) {
      return srgbCopy(linear, src.format);
    }
    // The first frame is written into toImage, and the others added to it.
    for (var i = 0; i < linear.numFrames; ++i) {
      writeSrgbFrame(linear.frames[i], i == 0 ? toImage : toImage.addFrame());
    }
    return toImage;
  }

  // You can't interpolate index pixels, so we need to convert the image
  // to a non-palette image if non-nearest interpolation is used.
  if (interpolation != Interpolation.nearest && src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }

  Image? firstFrame;
  for (final frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        toImage ??
        Image.from(frame, noAnimation: true);
    firstFrame ??= dst;
    for (var y = 0; y < dst.height; ++y) {
      final v = y / (dst.height - 1);
      for (var x = 0; x < dst.width; ++x) {
        final u = x / (dst.width - 1);
        // bilinear interpolation
        final srcPixelCoord = topLeft * (1 - u) * (1 - v) +
            topRight * u * (1 - v) +
            bottomLeft * (1 - u) * v +
            bottomRight * u * v;

        final srcPixel = interpolation == Interpolation.nearest
            ? frame.getPixel(srcPixelCoord.xi, srcPixelCoord.yi)
            : frame.getPixelInterpolate(srcPixelCoord.x, srcPixelCoord.y,
                interpolation: interpolation);

        dst.setPixel(x, y, srcPixel);
      }
    }
  }

  return firstFrame!;
}
