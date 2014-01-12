part of image;

const int PIXELATE_UPPERLEFT = 0;
const int PIXELATE_AVERAGE = 1;

/**
 * Pixelate the [src] image.
 *
 * [blockSize] determines the size of the pixelated blocks.
 * If [mode] is [PIXELATE_UPPERLEFT] then the upper-left corner of the block
 * will be used for the block color.  Otherwise if [mode] is PIXELATE_AVERAGE,
 * the average of all the pixels in the block will be used for the block color.
 */
Image pixelate(Image src, int blockSize, {int mode: PIXELATE_UPPERLEFT}) {
  if (blockSize <= 1) {
    return src;
  }

  int bs = blockSize - 1;

  switch (mode) {
    case PIXELATE_UPPERLEFT:
      for (int y = 0; y < src.height; y += blockSize) {
        for (int x = 0; x < src.width; x += blockSize) {
          if (src.boundsSafe(x, y)) {
            int c = src.getPixel(x, y);
            fillRect(src, x, y, x + bs, y + bs, c);
          }
        }
      }
      break;
    case PIXELATE_AVERAGE:
      for (int y = 0; y < src.height; y += blockSize) {
        for (int x = 0; x < src.width; x += blockSize) {
          int a = 0;
          int r = 0;
          int g = 0;
          int b = 0;
          int total = 0;

          for (int cy = 0; cy < blockSize; ++cy) {
            for (int cx = 0; cx < blockSize; ++cx) {
              if (!src.boundsSafe(x + cx, y + cy)) {
                continue;
              }
              int c = src.getPixel(x + cx, y + cy);
              a += getAlpha(c);
              r += getRed(c);
              g += getGreen(c);
              b += getBlue(c);
              total++;
            }
          }

          if (total > 0) {
            int c = getColor(r ~/ total, g ~/ total, b ~/ total, a ~/ total);
            fillRect(src, x, y, x + bs, y + bs, c);
          }
        }
      }
      break;
  }

  return src;
}
