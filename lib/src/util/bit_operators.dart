part of image;


int _shiftR(int v, int n) {
  if (v >= 0) {
    return v >> n;
  }

  // dart2js can't handle binary operations on negative numbers, so
  // until that issue is fixed (issues 16506, 1533), we'll have to do it
  // the slow way.
  return (v / _SHIFT_BITS[n]).floor();
}

int _shiftL(int v, int n) {
  if (v >= 0) {
    return v << n;
  }

  // dart2js can't handle binary operations on negative numbers, so
  // until that issue is fixed (issues 16506, 1533), we'll have to do it
  // the slow way.
  return (v * _SHIFT_BITS[n]);
}

const List<int> _SHIFT_BITS = const [
  1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384,
  32768, 65536];
