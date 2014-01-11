part of image;

/**
 *
 */
Image smooth(Image src, num w) {
  List<double> filter = [
    1.0, 1.0, 1.0,
    1.0, w,   1.0,
    1.0, 1.0, 1.0];

  return convolution(src, filter, w + 8, 0);
}
