import 'dart:math' as Math;

import '../color.dart';
import '../image.dart';
import '../util/min_max.dart';
import '../util/random.dart';

/// Gaussian noise type used by [noise].
const int NOISE_GAUSSIAN = 0;
/// Uniform noise type used by [noise].
const int NOISE_UNIFORM = 1;
/// Salt&Pepper noise type used by [noise].
const int NOISE_SALT_PEPPER = 2;
/// Poisson noise type used by [noise].
const int NOISE_POISSON = 3;
/// Rice noise type used by [noise].
const int NOISE_RICE = 4;

/**
 * Add random noise to pixel values.  [sigma] determines how strong the effect
 * should be.  [type] should be one of the following: [NOISE_GAUSSIAN],
 * [NOISE_UNIFORM], [NOISE_SALT_PEPPER], [NOISE_POISSON], or [NOISE_RICE].
 */
Image noise(Image image, double sigma, {int type: NOISE_GAUSSIAN,
  Math.Random random}) {
  if (random == null) {
    random = new Math.Random();
  }

  double nsigma = sigma;
  int m = 0;
  int M = 0;

  if (nsigma == 0.0 && type != NOISE_POISSON) {
    return image;
  }

  if (nsigma < 0.0 || type == NOISE_SALT_PEPPER) {
    List<int> mM = minMax(image);
    m = mM[0];
    M = mM[1];
  }

  if (nsigma < 0.0) {
    nsigma = -nsigma * (M - m) / 100.0;
  }

  final int len = image.length;
  switch (type) {
    case NOISE_GAUSSIAN:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = (getRed(c) + nsigma * grand(random)).toInt();
        int g = (getGreen(c) + nsigma * grand(random)).toInt();
        int b = (getBlue(c) + nsigma * grand(random)).toInt();
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NOISE_UNIFORM :
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = (getRed(c) + nsigma * crand(random)).toInt();
        int g = (getGreen(c) + nsigma * crand(random)).toInt();
        int b = (getBlue(c) + nsigma * crand(random)).toInt();
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NOISE_SALT_PEPPER:
      if (nsigma < 0) {
        nsigma = -nsigma;
      }
      if (M == m) {
        m = 0;
        M = 255;
      }
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        if (random.nextDouble() * 100.0 < nsigma) {
          int r = (random.nextDouble() < 0.5 ? M : m);
          int g = (random.nextDouble() < 0.5 ? M : m);
          int b = (random.nextDouble() < 0.5 ? M : m);
          int a = getAlpha(c);
          image[i] = getColor(r, g, b, a);
        }
      }
      break;
    case NOISE_POISSON:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = prand(random, getRed(c).toDouble());
        int g = prand(random, getGreen(c).toDouble());
        int b = prand(random, getBlue(c).toDouble());
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NOISE_RICE:
      double sqrt2 = Math.sqrt(2.0);
      for (int i = 0; i < len; ++i) {
        int c = image[i];

        double val0 = getRed(c) / sqrt2;
        double re = (val0 + nsigma * grand(random));
        double im = (val0 + nsigma * grand(random));
        double val = Math.sqrt(re * re + im * im);
        int r = val.toInt();

        val0 = getGreen(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = Math.sqrt(re * re + im * im);
        int g = val.toInt();

        val0 = getBlue(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = Math.sqrt(re * re + im * im);
        int b = val.toInt();

        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
  }

  return image;
}
