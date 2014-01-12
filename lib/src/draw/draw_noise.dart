part of image;

const int NOISE_GAUSSIAN = 0;
const int NOISE_UNIFORM = 1;
const int NOISE_SALT_PEPPER = 2;
const int NOISE_POISSON = 3;
const int NOISE_RICE = 4;

/**
 * Add random noise to pixel values.
 */
Image drawNoise(Image image, double sigma, {int type: NOISE_GAUSSIAN,
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
        int r = (red(c) + nsigma * grand(random)).toInt();
        int g = (green(c) + nsigma * grand(random)).toInt();
        int b = (blue(c) + nsigma * grand(random)).toInt();
        int a = alpha(c);
        image[i] = color(r, g, b, a);
      }
      break;
    case NOISE_UNIFORM :
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = (red(c) + nsigma * crand(random)).toInt();
        int g = (green(c) + nsigma * crand(random)).toInt();
        int b = (blue(c) + nsigma * crand(random)).toInt();
        int a = alpha(c);
        image[i] = color(r, g, b, a);
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
          int a = alpha(c);
          image[i] = color(r, g, b, a);
        }
      }
      break;
    case NOISE_POISSON:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = prand(random, red(c).toDouble());
        int g = prand(random, green(c).toDouble());
        int b = prand(random, blue(c).toDouble());
        int a = alpha(c);
        image[i] = color(r, g, b, a);
      }
      break;
    case NOISE_RICE:
      double sqrt2 = Math.sqrt(2.0);
      for (int i = 0; i < len; ++i) {
        int c = image[i];

        double val0 = red(c) / sqrt2;
        double re = (val0 + nsigma * grand(random));
        double im = (val0 + nsigma * grand(random));
        double val = Math.sqrt(re * re + im * im);
        int r = val.toInt();

        val0 = green(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = Math.sqrt(re * re + im * im);
        int g = val.toInt();

        val0 = blue(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = Math.sqrt(re * re + im * im);
        int b = val.toInt();

        int a = alpha(c);
        image[i] = color(r, g, b, a);
      }
      break;
    default :
      throw new ImageException('Invalid noise type ${type}');
  }

  return image;
}
