import '../color/color_util.dart';
import '../image/image.dart';

/// Convert the image to grayscale.
Image grayscale(Image src) {
  if (src.hasPalette) {

  } else {
    for (var p in src) {
      final l = getLuminanceRgb(p.r, p.g, p.b);
      p.r = l;
      p.g = l;
      p.b = l;
    }
  }

  return src;
}
