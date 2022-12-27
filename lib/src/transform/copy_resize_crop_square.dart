import 'dart:typed_data';

import '../image/image.dart';
import '../util/image_exception.dart';

/// Returns a resized and square cropped copy of the [src] image of [size] size.
Image copyResizeCropSquare(Image src, int size) {
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

  final scaleX = Int32List(size);
  for (var x = 0; x < size; ++x) {
    scaleX[x] = ((x + xOffset) * dx).toInt();
  }

  Image? firstFrame;
  for (final frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame, width: size, height: size);
    firstFrame ??= dst;

    for (var y = 0; y < size; ++y) {
      final y2 = ((y + yOffset) * dy).toInt();
      for (var x = 0; x < size; ++x) {
        dst.setPixel(x, y, frame.getPixel(scaleX[x], y2));
      }
    }
  }

   return firstFrame!;
}
