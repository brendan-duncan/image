part of image;

/**
 * Apply a mean-removal convolution filter.
 */
Image meanRemoval(Image src) {
  const List<double> filter = const[
    -1.0, -1.0, -1.0,
    -1.0,  9.0, -1.0,
    -1.0, -1.0, -1.0];

  return convolution(src, filter, 1, 0);
}
