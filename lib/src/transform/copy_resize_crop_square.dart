import 'dart:typed_data';

import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/image_exception.dart';

/// Returns a resized and square cropped copy of the [src] image of [size] size.
Image copyResizeCropSquare(Image src, int size, {
    Interpolation interpolation = Interpolation.nearest }) {
  if (size <= 0) {
    throw ImageException('Invalid size');
  }

  var height = size;
  var width = size;
  if (src.width < src.height) {
    height = (size * (src.height / src.width)).toInt();
  } else if (src.width > src.height) {
    width = (size * (src.width / src.height)).toInt();
  }

  final dy = src.height / height;
  final dx = src.width / width;

  final xOffset = (width - size) ~/ 2;
  final yOffset = (height - size) ~/ 2;

  final scaleX = interpolation == Interpolation.nearest ? Int32List(size)
      : null;

  if (scaleX != null) {
    for (var x = 0; x < size; ++x) {
      scaleX[x] = ((x + xOffset) * dx).toInt();
    }
  }

  Image? firstFrame;
  for (final frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame, width: size, height: size);
    firstFrame ??= dst;

    if (interpolation == Interpolation.nearest) {
      for (var y = 0; y < size; ++y) {
        final y2 = ((y + yOffset) * dy).toInt();
        for (var x = 0; x < size; ++x) {
          dst.setPixel(x, y, frame.getPixel(scaleX![x], y2));
        }
      }
    } else {
      for (final p in dst) {
        final x = p.x * dx;
        final y = p.y * dy;
        p.set(frame.getPixelInterpolate(x, y, interpolation: interpolation));
      }
    }
  }

   return firstFrame!;
}
