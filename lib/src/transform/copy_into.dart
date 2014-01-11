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
               int dst_x, int dst_y, int src_x, int src_y,
               int dst_w, int dst_h, int src_w, int src_h) {
  double dsw = src_w / dst_w;
  double dsh = src_h / dst_h;

  int dy = dst_y;
  for (int yi = 0; yi < dst_h; ++yi, ++dy) {
    int sy = (dy * dsh).toInt() + src_y;
    int dx = dst_x;
    for (int xi = 0; xi < dst_w; ++xi, ++dx) {
      int sx = (dx * dsw).toInt() + src_x;

      dst.setPixel(dx, dy, src.getPixel(sx, sy));
    }
  }

  return dst;
}
