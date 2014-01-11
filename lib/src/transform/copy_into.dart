part of image;

/**
 * Copies a rectangular portion of one image to another image. [dst] is the
 * destination image, [src] is the source image identifier.
 *
 * In other words, copyResized() will take an rectangular area from src of
 * width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
 * in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
 * position ([dst_x],[dst_y]).
 *
 * If the source and destination coordinates and width and heights differ,
 * appropriate stretching or shrinking of the image fragment will be performed.
 * The coordinates refer to the upper left corner. This function can be used to
 * copy regions within the same image (if [dst] is the same as [src])
 * but if the regions overlap the results will be unpredictable.
 */
Image copyInto(Image dst, Image src,
               {int dstX, int dstY, int srcX, int srcY,
                int srcW, int srcH, bool blend: false}) {
  if (dstX == null) {
    dstX = 0;
  }
  if (dstY == null) {
    dstY = 0;
  }
  if (srcX == null) {
    srcX = 0;
  }
  if (srcY == null) {
    srcY = 0;
  }
  if (srcW == null) {
    srcW = src.width;
  }
  if (srcH == null) {
    srcH = src.height;
  }

  for (int y = 0; y < srcH; ++y) {
    for (int x = 0; x < srcW; ++x) {
      if (blend) {
        dst.setPixelBlend(dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      } else {
        dst.setPixel(dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      }
    }
  }

  /*double dsw = src_w / dst_w;
  double dsh = src_h / dst_h;

  for (int yi = 0, sy = src_y; yi < src_h; ++yi, ++sy) {
    int dy = sy + dst_y;
    for (int xi = 0, sx = src_x; xi < src_w; ++xi, ++sx) {
      int dx = sx + dst_x;
      dst.setPixel(dx, dy, 0xff0000ff);//src.getPixel(sx, sy));
    }
  }*/
  /*for (int yi = 0, dy = dst_y; yi < dst_h; ++yi, ++dy) {
    int sy = (dy * dsh).toInt() + src_y;
    for (int xi = 0, dx = dst_x; xi < dst_w; ++xi, ++dx) {
      int sx = (dx * dsw).toInt() + src_x;
      dst.setPixel(dx, dy, src.getPixel(sx, sy));
    }
  }*/

  return dst;
}
