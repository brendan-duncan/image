import '../image/image.dart';

/// Invert the colors of the [src] image.
Image invert(Image src) {
  final max = src.maxChannelValue;
  for (final frame in src.frames) {
    if (src.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        final r = max - p.getRed(i);
        final g = max - p.getGreen(i);
        final b = max - p.getBlue(i);
        p.setColor(i, r, g, b);
      }
    } else {

      if (max != 0.0) {
        for (var p in frame) {
          p..r = max - p.r
          ..g = max - p.g
          ..b = max - p.b;
        }
      }
    }
  }
  return src;
}
