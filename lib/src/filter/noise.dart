import 'dart:math';

import '../color.dart';
import '../image.dart';
import '../util/min_max.dart';
import '../util/random.dart';

enum NoiseType {
  gaussian,
  uniform,
  salt_pepper,
  poisson,
  rice
}

/// Add random noise to pixel values. [sigma] determines how strong the effect
/// should be. [type] should be one of the following: [NoiseType.gaussian],
/// [NoiseType.uniform], [NoiseType.salt_pepper], [NoiseType.poisson],
/// or [NoiseType.rice].
Image noise(Image image, num sigma,
           {NoiseType type = NoiseType.gaussian,
            Random random}) {
  if (random == null) {
    random = Random();
  }

  num nsigma = sigma;
  int m = 0;
  int M = 0;

  if (nsigma == 0.0 && type != NoiseType.poisson) {
    return image;
  }

  if (nsigma < 0.0 || type == NoiseType.salt_pepper) {
    List<int> mM = minMax(image);
    m = mM[0];
    M = mM[1];
  }

  if (nsigma < 0.0) {
    nsigma = -nsigma * (M - m) / 100.0;
  }

  final int len = image.length;
  switch (type) {
    case NoiseType.gaussian:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = (getRed(c) + nsigma * grand(random)).toInt();
        int g = (getGreen(c) + nsigma * grand(random)).toInt();
        int b = (getBlue(c) + nsigma * grand(random)).toInt();
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NoiseType.uniform:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = (getRed(c) + nsigma * crand(random)).toInt();
        int g = (getGreen(c) + nsigma * crand(random)).toInt();
        int b = (getBlue(c) + nsigma * crand(random)).toInt();
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NoiseType.salt_pepper:
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
    case NoiseType.poisson:
      for (int i = 0; i < len; ++i) {
        int c = image[i];
        int r = prand(random, getRed(c).toDouble());
        int g = prand(random, getGreen(c).toDouble());
        int b = prand(random, getBlue(c).toDouble());
        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NoiseType.rice:
      num sqrt2 = sqrt(2.0);
      for (int i = 0; i < len; ++i) {
        int c = image[i];

        num val0 = getRed(c) / sqrt2;
        num re = (val0 + nsigma * grand(random));
        num im = (val0 + nsigma * grand(random));
        num val = sqrt(re * re + im * im);
        int r = val.toInt();

        val0 = getGreen(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = sqrt(re * re + im * im);
        int g = val.toInt();

        val0 = getBlue(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = sqrt(re * re + im * im);
        int b = val.toInt();

        int a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
  }

  return image;
}
