part of image;

/**
 *
 */
Image edgeDetectQuick(Image src) {
  const List<double> filter = const[
    -1.0, 0.0, -1.0,
     0.0, 4.0,  0.0,
    -1.0, 0.0, -1.0];

  return convolution(src, filter, 1, 127);
}
