import '../draw/fill_rect.dart';
import '../image/image.dart';

enum PixelateMode {
  /// Use the top-left pixel of a block for the block color.
  upperLeft,
  /// Use the average of the pixels within a block for the block color.
  average
}

/// Pixelate the [src] image.
///
/// [blockSize] determines the size of the pixelated blocks.
/// If [mode] is [PixelateMode.upperLeft] then the upper-left corner of the
/// block will be used for the block color. Otherwise if [mode] is
/// [PixelateMode.average], the average of all the pixels in the block will be
/// used for the block color.
Image pixelate(Image src, int blockSize,
    { PixelateMode mode = PixelateMode.upperLeft }) {
  if (blockSize <= 1) {
    return src;
  }

  final bs = blockSize - 1;

  for (final frame in src.frames) {
    final w = frame.width;
    final h = frame.height;
    switch (mode) {
      case PixelateMode.upperLeft:
        for (final p in frame) {
          final x2 = (p.x ~/ blockSize) * blockSize;
          final y2 = (p.y ~/ blockSize) * blockSize;
          final p2 = frame.getPixel(x2, y2);
          p.set(p2);
        }
        break;
      case PixelateMode.average:
        num r = 0;
        num g = 0;
        num b = 0;
        num a = 0;
        var lx = -1;
        var ly = -1;
        for (final p in frame) {
          final x2 = (p.x ~/ blockSize) * blockSize;
          final y2 = (p.y ~/ blockSize) * blockSize;
          if (x2 != lx || y2 <= ly) {
            lx = x2;
            ly = y2;
            r = 0;
            g = 0;
            b = 0;
            a = 0;
            for (var by = 0, by2 = y2; by < blockSize && by2 < h; ++by, ++by2) {
              for (var bx = 0, bx2 = x2; bx < blockSize && bx2 < w;
                  ++bx, ++bx2) {
                final p2 = frame.getPixel(bx2, by2);
                r += p2.r;
                g += p2.g;
                b += p2.b;
                a += p2.a;
              }
            }
            final total = blockSize * blockSize;
            r /= total;
            g /= total;
            b /= total;
            a /= total;
          }

          p.setColor(r, g, b, a);
        }
        break;
    }
  }
  return src;
}
