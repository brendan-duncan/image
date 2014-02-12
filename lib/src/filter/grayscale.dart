part of image;

/**
 * Convert the image to grayscale.
 */
Image grayscale(Image src) {
  Uint8List p = src.getBytes();
  for (int i = 0, len = p.length; i < len; i += 4) {
    int l = getLuminanceRGB(p[i], p[i + 1], p[i + 2]);
    p[i] = l;
    p[i + 1] = l;
    p[i + 2] = l;
  }
  return src;
}
