part of image;

/**
 * Apply an emboss convolution filter.
 */
Image emboss(Image src) {
  const List<double> filter = const[
    1.5, 0.0,  0.0,
    0.0, 0.0,  0.0,
    0.0, 0.0, -1.5];

  return convolution(src, filter, 1, 127);
}
