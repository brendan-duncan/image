part of image;

/**
 * Draw a rectangle in the image [src] with the [color].
 */
Image drawRect(Image src, int x1, int y1, int x2, int y2, int color) {
  int x0 = Math.min(x1, x2);
  int y0 = Math.min(y1, y2);
  x1 = Math.max(x1, x2);
  y1 = Math.max(y1, y2);

  drawLine(src, x0, y0, x1, y0, color);
  drawLine(src, x1, y0, x1, y1, color);
  drawLine(src, x0, y1, x1, y1, color);
  drawLine(src, x0, y0, x0, y1, color);

  return src;
}
