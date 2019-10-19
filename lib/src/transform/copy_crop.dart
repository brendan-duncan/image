import '../image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src, int x, int y, int w, int h) {
  Image dst =
      Image(w, h, channels: src.channels, exif: src.exif, iccp: src.iccProfile);

  for (int yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (int xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}
