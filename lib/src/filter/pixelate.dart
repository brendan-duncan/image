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
    switch (mode) {
      case PixelateMode.upperLeft:
        for (var y = 0; y < frame.height; y += blockSize) {
          for (var x = 0; x < frame.width; x += blockSize) {
            if (frame.isBoundsSafe(x, y)) {
              final c = frame.getPixel(x, y);
              fillRect(frame, x, y, x + bs, y + bs, c);
            }
          }
        }
        break;
      case PixelateMode.average:
        for (var y = 0; y < frame.height; y += blockSize) {
          for (var x = 0; x < frame.width; x += blockSize) {
            num a = 0;
            num r = 0;
            num g = 0;
            num b = 0;
            var total = 0;

            for (var cy = 0; cy < blockSize; ++cy) {
              for (var cx = 0; cx < blockSize; ++cx) {
                if (!frame.isBoundsSafe(x + cx, y + cy)) {
                  continue;
                }
                final c = frame.getPixel(x + cx, y + cy);
                a += c.a;
                r += c.r;
                g += c.g;
                b += c.b;
                total++;
              }
            }

            if (total > 0) {
              final c = frame.getColor(r / total, g / total, b / total,
                  a / total);
              fillRect(frame, x, y, x + bs, y + bs, c);
            }
          }
        }
        break;
    }
  }
  return src;
}
