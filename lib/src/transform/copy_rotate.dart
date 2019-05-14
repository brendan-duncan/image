import 'dart:math';

import '../image.dart';
import '../util/interpolation.dart';

/// Returns a copy of the [src] image, rotated by [angle] degrees.
Image copyRotate(Image src, num angle,
    {Interpolation interpolation = Interpolation.nearest}) {
  num nangle = angle % 360.0;

  // Optimized version for orthogonal angles.
  if ((nangle % 90.0) == 0.0) {
    int wm1 = src.width - 1;
    int hm1 = src.height - 1;

    int iangle = nangle ~/ 90.0;
    switch (iangle) {
      case 1: // 90 deg.
        Image dst =
            Image(src.height, src.width, channels: src.channels,
                exif: src.exif, iccp: src.iccProfile);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(y, hm1 - x));
          }
        }
        return dst;
      case 2: // 180 deg.
        Image dst =
            Image(src.width, src.height, channels: src.channels, exif: src.exif,
                iccp: src.iccProfile);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - x, hm1 - y));
          }
        }
        return dst;
      case 3: // 270 deg.
        Image dst =
            Image(src.height, src.width, channels: src.channels, exif: src.exif,
                iccp: src.iccProfile);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - y, x));
          }
        }
        return dst;
      default: // 0 deg.
        return Image.from(src);
    }
  }

  // Generic angle.
  num rad = (nangle * pi / 180.0);
  num ca = cos(rad);
  num sa = sin(rad);
  num ux = (src.width * ca).abs();
  num uy = (src.width * sa).abs();
  num vx = (src.height * sa).abs();
  num vy = (src.height * ca).abs();
  num w2 = 0.5 * src.width;
  num h2 = 0.5 * src.height;
  num dw2 = 0.5 * (ux + vx);
  num dh2 = 0.5 * (uy + vy);

  Image dst = Image((ux + vx).toInt(), (uy + vy).toInt(),
      channels: Channels.rgba, exif: src.exif, iccp: src.iccProfile);

  for (int y = 0; y < dst.height; ++y) {
    for (int x = 0; x < dst.width; ++x) {
      int c = src.getPixelInterpolate(w2 + (x - dw2) * ca + (y - dh2) * sa,
          h2 - (x - dw2) * sa + (y - dh2) * ca, interpolation);
      dst.setPixel(x, y, c);
    }
  }

  return dst;
}
