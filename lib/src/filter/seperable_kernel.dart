import '../color.dart';
import '../image.dart';

/// A kernel object to use with [seperableConvolution] filtering.
class SeperableKernel {
  final List<double> coefficients;
  final int size;

  /// Create a seperable convolution kernel for the given [radius].
  SeperableKernel(int radius)
      : coefficients = List<double>(2 * radius + 1),
        this.size = radius;

  /// Get the number of coefficients in the kernel.
  int get length => coefficients.length;

  /// Get a coefficient from the kernel.
  double operator [](int index) => coefficients[index];

  /// Set a coefficient in the kernel.
  void operator []=(int index, double c) {
    coefficients[index] = c;
  }

  /// Apply the kernel to the [src] image, storing the results in [dst],
  /// for a single dimension. If [horizontal is true, the filter will be
  /// applied to the horizontal axis, otherwise it will be appied to the
  /// vertical axis.
  void apply(Image src, Image dst, {bool horizontal = true}) {
    if (horizontal) {
      for (int y = 0; y < src.height; ++y) {
        _applyCoeffsLine(src, dst, y, src.width, horizontal);
      }
    } else {
      for (int x = 0; x < src.width; ++x) {
        _applyCoeffsLine(src, dst, x, src.height, horizontal);
      }
    }
  }

  /// Scale all of the coefficients by [s].
  void scaleCoefficients(double s) {
    for (int i = 0; i < coefficients.length; ++i) {
      coefficients[i] *= s;
    }
  }

  int _reflect(int max, int x) {
    if (x < 0) {
      return -x;
    }
    if (x >= max) {
      return max - (x - max) - 1;
    }
    return x;
  }

  void _applyCoeffsLine(
      Image src, Image dst, int y, int width, bool horizontal) {
    for (int x = 0; x < width; x++) {
      double r = 0.0;
      double g = 0.0;
      double b = 0.0;
      double a = 0.0;

      for (int j = -size, j2 = 0; j <= size; ++j, ++j2) {
        double coeff = coefficients[j2];
        int gr = _reflect(width, x + j);

        int sc = (horizontal) ? src.getPixel(gr, y) : src.getPixel(y, gr);

        r += coeff * getRed(sc);
        g += coeff * getGreen(sc);
        b += coeff * getBlue(sc);
        a += coeff * getAlpha(sc);
      }

      int c = getColor(
          (r > 255.0 ? 255.0 : r).toInt(),
          (g > 255.0 ? 255.0 : g).toInt(),
          (b > 255.0 ? 255.0 : b).toInt(),
          (a > 255.0 ? 255.0 : a).toInt());

      if (horizontal) {
        dst.setPixel(x, y, c);
      } else {
        dst.setPixel(y, x, c);
      }
    }
  }
}
