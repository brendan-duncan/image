import '../image.dart';

enum Flip {
  /// Flip the image horizontally.
  horizontal,
  /// Flip the image vertically.
  vertical,
  /// Flip the image both horizontally and vertically.
  both
}

/// Flips the [src] image using the given [mode], which can be one of:
/// [Flip.horizontal], [Flip.vertical], or [Flip.both].
Image flip(Image src, Flip mode) {
  switch (mode) {
    case Flip.horizontal:
      flipHorizontal(src);
      break;
    case Flip.vertical:
      flipVertical(src);
      break;
    case Flip.both:
      flipVertical(src);
      flipHorizontal(src);
      break;
  }

  return src;
}

/// Flip the [src] image vertically.
Image flipVertical(Image src) {
  int w = src.width;
  int h = src.height;
  int h2 = h ~/ 2;
  for (int y = 0; y < h2; ++y) {
    int y1 = y * w;
    int y2 = (h - 1 - y) * w;
    for (int x = 0; x < w; ++x) {
      int t = src[y2 + x];
      src[y2 + x] = src[y1 + x];
      src[y1 + x] = t;
    }
  }
  return src;
}

/// Flip the src image horizontally.
Image flipHorizontal(Image src) {
  int w = src.width;
  int h = src.height;
  int w2 = src.width ~/ 2;
  for (int y = 0; y < h; ++y) {
    int y1 = y * w;
    for (int x = 0; x < w2; ++x) {
      int x2 = (w - 1 - x);
      int t = src[y1 + x2];
      src[y1 + x2] = src[y1 + x];
      src[y1 + x] = t;
    }
  }
  return src;
}
