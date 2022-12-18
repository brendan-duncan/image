import '../image/image.dart';

enum FlipDirection {
  /// Flip the image horizontally.
  horizontal,
  /// Flip the image vertically.
  vertical,
  /// Flip the image both horizontally and vertically.
  both
}

/// Flips the [src] image using the given [direction], which can be one of:
/// [FlipDirection.horizontal], [FlipDirection.vertical],
/// or [FlipDirection.both].
Image flip(Image src, FlipDirection direction) {
  switch (direction) {
    case FlipDirection.horizontal:
      flipHorizontal(src);
      break;
    case FlipDirection.vertical:
      flipVertical(src);
      break;
    case FlipDirection.both:
      flipHorizontalVertical(src);
      break;
  }

  return src;
}

/// Flip the [src] image vertically.
Image flipVertical(Image src) {
  final w = src.width;
  final h = src.height;
  final h2 = h ~/ 2;

  for (var y = 0, y2 = h - 1; y < h2; ++y, --y2) {
    for (var x = 0; x < w; ++x) {
      final p1 = src.getPixel(x, y);
      final p2 = src.getPixel(x, y2);
      var t = p1.r;
      p1.r = p2.r;
      p2.r = t;

      t = p1.g;
      p1.g = p2.g;
      p2.g = t;

      t = p1.b;
      p1.b = p2.b;
      p2.b = t;

      t = p1.a;
      p1.a = p2.a;
      p2.a = t;
    }
  }
  return src;
}

/// Flip the src image horizontally.
Image flipHorizontal(Image src) {
  final w = src.width;
  final h = src.height;
  final w2 = w ~/ 2;
  for (var y = 0; y < h; ++y) {
    for (var x = 0, x2 = w - 1; x < w2; ++x, --x2) {
      final p1 = src.getPixel(x, y);
      final p2 = src.getPixel(x2, y);
      var t = p1.r;
      p1.r = p2.r;
      p2.r = t;

      t = p1.g;
      p1.g = p2.g;
      p2.g = t;

      t = p1.b;
      p1.b = p2.b;
      p2.b = t;

      t = p1.a;
      p1.a = p2.a;
      p2.a = t;
    }
  }
  return src;
}

/// Flip the src image horizontally and vertically.
Image flipHorizontalVertical(Image src) {
  final w = src.width;
  final h = src.height;
  final h2 = h ~/ 2;

  for (var y = 0, y2 = h - 1; y < h2; ++y, --y2) {
    for (var x = 0, x2 = w - 1; x < w; ++x, --x2) {
      final p1 = src.getPixel(x, y);
      final p2 = src.getPixel(x2, y2);
      var t = p1.r;
      p1.r = p2.r;
      p2.r = t;

      t = p1.g;
      p1.g = p2.g;
      p2.g = t;

      t = p1.b;
      p1.b = p2.b;
      p2.b = t;

      t = p1.a;
      p1.a = p2.a;
      p2.a = t;
    }
  }
  return src;
}