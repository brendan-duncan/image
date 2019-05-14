import 'dart:typed_data';

import '../image.dart';
import '../image_exception.dart';

/// Returns a resized and square cropped copy of the [src] image of [size] size.
Image copyResizeCropSquare(Image src, int size) {
  if (size <= 0) {
    throw ImageException('Invalid size');
  }

  int height = size;
  int width = size;
  if (src.width < src.height){
    height = (size * (src.height / src.width)).toInt();
  }
  else if (src.width > src.height){
    width = (size * (src.width / src.height)).toInt();
  }

  Image dst = Image(size, size, channels: src.channels, exif: src.exif,
      iccp: src.iccProfile);

  double dy = src.height / height;
  double dx = src.width / width;

  int xOffset = ((width - size) ~/ 2);
  int yOffset = ((height - size) ~/ 2);

  final scaleX = Int32List(size);
  for (int x = 0; x < size; ++x) {
    scaleX[x] = ((x + xOffset) * dx).toInt();
  }

  for (int y = 0; y < size; ++y) {
    int y2 = ((y + yOffset) * dy).toInt();
    for (int x = 0; x < size; ++x) {
      dst.setPixel(x, y, src.getPixel(scaleX[x], y2));
    }
  }

  return dst;
}
