import '../image/image.dart';

/// Invert the colors of the [src] image.
Image invert(Image src) {
  if (src.hasPalette) {

  } else {
    final max = src.maxChannelValue;
    if (max != 0.0) {
      for (var p in src) {
        p.r = max - p.r;
        p.g = max - p.g;
        p.b = max - p.b;
      }
    }
  }
  return src;
}
