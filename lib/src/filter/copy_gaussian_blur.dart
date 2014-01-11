part of image;

Map<int, List<double>> _gaussianCache = {};

/**
 *
 */
Image copyGaussianBlur(Image src, int radius) {
  /*if (radius == 3) {
    const List<double> filter = const[
        1.0, 2.0, 1.0,
        2.0, 4.0, 0.0,
        1.0, 2.0, 1.0];

    return convolution(new Image.from(src), filter, 16, 0);
  }*/

  List<double> coefficients;

  if (_gaussianCache.containsKey(radius)) {
    coefficients = _gaussianCache[radius];
  } else {
    // Compute coefficients
    double sigma = (2.0 / 3.0) * radius;
    double s = 2.0 * sigma * sigma;
    int count = 2 * radius + 1;
    coefficients = new List<double>(count);
    double sum = 0.0;
    for (int x = -radius; x <= radius; ++x) {
      double c = Math.exp(-(x * x) / s);
      sum += c;
      coefficients[x + radius] = c;
    }
    // Normalize the coefficients
    for (int i = 0; i < count; ++i) {
      coefficients[i] /= sum;
    }

    _gaussianCache[radius] = coefficients;
  }

  // Apply the filter horizontally
  Image tmp = new Image.from(src);
  _gaussianApplyCoeffs(src, tmp, coefficients, radius, true);

  // Apply the filter vertically
  Image result = new Image.from(tmp);
  _gaussianApplyCoeffs(tmp, result, coefficients, radius, false);

  return result;
}

void _gaussianApplyCoeffs(Image src, Image dst, List<double> coeffs,
                          int radius, bool horizontal) {
  int numLines;
  int lineLen;
  if (horizontal) {
    numLines = src.height;
    lineLen = src.width;
  } else {
    numLines = src.width;
    lineLen = src.height;
  }

  for (int line = 0; line < numLines; line++) {
    _gaussianApplyCoeffsLine(src, dst, line, lineLen, coeffs, radius,
                             horizontal);
  }
}

int _gaussianReflect(int max, int x) {
  if (x < 0) return -x;
  if (x >= max) return max - (x - max) - 1;
  return x;
}

void _gaussianApplyCoeffsLine(Image src, Image dst, int line, int linelen,
                              List<double> coeffs, int radius,
                              bool horizontal) {
  for (int ndx = 0; ndx < linelen; ndx++) {
    double r = 0.0, g = 0.0, b = 0.0, a = 0.0;

    for (int cndx = -radius; cndx <= radius; cndx++) {
      double coeff = coeffs[cndx + radius];
      int rndx = _gaussianReflect(linelen, ndx + cndx);

      int sc = (horizontal) ? src.getPixel(rndx, line) :
               src.getPixel(line, rndx);

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
      dst.setPixel(ndx, line, c);
    } else {
      dst.setPixel(line, ndx, c);
    }
  }
}
