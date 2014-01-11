part of image;

Map<int, SeperableKernel> _gaussianKernelCache = {};

/**
 * Apply gaussian blur to the [src] image.
 *
 * A new image is returned.
 */
Image copyGaussianBlur(Image src, int radius) {
  SeperableKernel kernel;

  if (_gaussianKernelCache.containsKey(radius)) {
    kernel = _gaussianKernelCache[radius];
  } else {
    // Compute coefficients
    double sigma = radius * (2.0 / 3.0);
    double s = 2.0 * sigma * sigma;

    kernel = new SeperableKernel(radius);

    double sum = 0.0;
    for (int x = -radius; x <= radius; ++x) {
      double c = Math.exp(-(x * x) / s);
      sum += c;
      kernel[x + radius] = c;
    }
    // Normalize the coefficients
    kernel.scaleCoefficients(1.0 / sum);

    // Cache the kernel for this radius so we don't have to recompute it
    // next time.
    _gaussianKernelCache[radius] = kernel;
  }

  return seperableConvolution(src, kernel);
}

/*void _gaussianApplyCoeffs(Image src, Image dst, List<double> kernel,
                          int radius, bool horizontal) {
  if (horizontal) {
    for (int y = 0; y < src.height; ++y) {
      _gaussianApplyCoeffsLine(src, dst, y, src.width, kernel, radius,
          horizontal);
    }
  } else {
    for (int x = 0; x < src.width; ++x) {
      _gaussianApplyCoeffsLine(src, dst, x, src.height, kernel, radius,
          horizontal);
    }
  }
}

int _gaussianReflect(int max, int x) {
  if (x < 0) {
    return -x;
  }
  if (x >= max) {
    return max - (x - max) - 1;
  }
  return x;
}

void _gaussianApplyCoeffsLine(Image src, Image dst,
                              int y, int width,
                              List<double> kernel, int radius,
                              bool horizontal) {
  for (int x = 0; x < width; x++) {
    double r = 0.0;
    double g = 0.0;
    double b = 0.0;
    double a = 0.0;

    for (int j = -radius, j2 = 0; j <= radius; ++j, ++j2) {
      double coeff = kernel[j2];
      int gr = _gaussianReflect(width, x + j);

      int sc = (horizontal) ?
               src.getPixel(gr, y) :
               src.getPixel(y, gr);

      r += coeff * getRed(sc);
      g += coeff * getGreen(sc);
      b += coeff * getBlue(sc);
      a += coeff * getAlpha(sc);
    }

    int c = getColor((r > 255.0 ? 255.0 : r).toInt(),
                     (g > 255.0 ? 255.0 : g).toInt(),
                     (b > 255.0 ? 255.0 : b).toInt(),
                     (a > 255.0 ? 255.0 : a).toInt());

    if (horizontal) {
      dst.setPixel(x, y, c);
    } else {
      dst.setPixel(y, x, c);
    }
  }
}*/
