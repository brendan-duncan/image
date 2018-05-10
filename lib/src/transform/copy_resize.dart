import 'dart:typed_data';

import '../color.dart';
import '../image.dart';
import '../image_exception.dart';
import '../util/interpolation.dart';

/**
 * Returns a resized copy of the [src] image.
 * If [height] is -1, then it will be determined by the aspect
 * ratio of [src] and [width].
 */
Image copyResize(Image src, int width, [int height = -1,
                 int interpolation = LINEAR]) {
  if (height < 0) {
    height = (width * (src.height / src.width)).toInt();
  }

  if (width <= 0 || height <= 0) {
    throw new ImageException('Invalid size');
  }

  Image dst = new Image(width, height, src.format);

  double dy = src.height / height;
  double dx = src.width / width;

  if (interpolation == AVERAGE) {
    Uint8List sData = src.getBytes();
    int sw4 = src.width * 4;

    for (int y = 0; y < height; ++y) {
      int y1 = (y * dy).toInt();
      int y2 = ((y + 1) * dy).toInt();
      if (y2 == y1) {
        y2++;
      }

      for (int x = 0; x < width; ++x) {
        int x1 = (x * dx).toInt();
        int x2 = ((x + 1) * dx).toInt();
        if (x2 == x1) {
          x2++;
        }

        int r = 0;
        int g = 0;
        int b = 0;
        int a = 0;
        int np = 0;
        for (int sy = y1; sy < y2; ++sy) {
          int si = sy * sw4 + x1 * 4;
          for (int sx = x1; sx < x2; ++sx, ++np) {
            r += sData[si++];
            g += sData[si++];
            b += sData[si++];
            a += sData[si++];
          }
        }
        dst.setPixel(x, y, getColor(r ~/ np, g ~/ np, b ~/ np, a ~/ np));
      }
    }
  } else {
    // Copy the pixels from this image to the new image.
    for (int y = 0; y < height; ++y) {
     double y2 = (y * dy);
     for (int x = 0; x < width; ++x) {
       double x2 = (x * dx);
       dst.setPixel(x, y, src.getPixelInterpolate(x2, y2, interpolation));
     }
    }
  }

  return dst;
}
