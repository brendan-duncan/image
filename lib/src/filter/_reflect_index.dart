/// Reflects [x] into the range [0, max), for sampling past the edges of an
/// image. Clamped, for kernels larger than the image.
int reflectIndex(int max, int x) {
  if (x < 0) {
    x = -x;
  }
  if (x >= max) {
    x = max - (x - max) - 1;
  }
  return x < 0
      ? 0
      : x >= max
          ? max - 1
          : x;
}
