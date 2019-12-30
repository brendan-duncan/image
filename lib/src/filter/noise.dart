import 'dart:math';

import '../color.dart';
import '../image.dart';
import '../util/min_max.dart';
import '../util/random.dart';

enum NoiseType { gaussian, uniform, salt_pepper, poisson, rice }

/// Add random noise to pixel values. [sigma] determines how strong the effect
/// should be. [type] should be one of the following: [NoiseType.gaussian],
/// [NoiseType.uniform], [NoiseType.salt_pepper], [NoiseType.poisson],
/// or [NoiseType.rice].
Image noise(Image image, num sigma,
    {NoiseType type = NoiseType.gaussian, Random random}) {
  random ??= Random();

  var nsigma = sigma;
  var m = 0;
  var M = 0;

  if (nsigma == 0.0 && type != NoiseType.poisson) {
    return image;
  }

  if (nsigma < 0.0 || type == NoiseType.salt_pepper) {
    var mM = minMax(image);
    m = mM[0];
    M = mM[1];
  }

  if (nsigma < 0.0) {
    nsigma = -nsigma * (M - m) / 100.0;
  }

  final len = image.length;
  switch (type) {
    case NoiseType.gaussian:
      for (var i = 0; i < len; ++i) {
        var c = image[i];
        var r = (getRed(c) + nsigma * grand(random)).toInt();
        var g = (getGreen(c) + nsigma * grand(random)).toInt();
        var b = (getBlue(c) + nsigma * grand(random)).toInt();
        var a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NoiseType.uniform:
      for (var i = 0; i < len; ++i) {
        var c = image[i];
        var r = (getRed(c) + nsigma * crand(random)).toInt();
        var g = (getGreen(c) + nsigma * crand(random)).toInt();
        var b = (getBlue(c) + nsigma * crand(random)).toInt();
        var a = getAlpha(c);
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
      for (var i = 0; i < len; ++i) {
        var c = image[i];
        if (random.nextDouble() * 100.0 < nsigma) {
          var r = (random.nextDouble() < 0.5 ? M : m);
          var g = (random.nextDouble() < 0.5 ? M : m);
          var b = (random.nextDouble() < 0.5 ? M : m);
          var a = getAlpha(c);
          image[i] = getColor(r, g, b, a);
        }
      }
      break;
    case NoiseType.poisson:
      for (var i = 0; i < len; ++i) {
        var c = image[i];
        var r = prand(random, getRed(c).toDouble());
        var g = prand(random, getGreen(c).toDouble());
        var b = prand(random, getBlue(c).toDouble());
        var a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
    case NoiseType.rice:
      num sqrt2 = sqrt(2.0);
      for (var i = 0; i < len; ++i) {
        var c = image[i];

        var val0 = getRed(c) / sqrt2;
        var re = (val0 + nsigma * grand(random));
        var im = (val0 + nsigma * grand(random));
        var val = sqrt(re * re + im * im);
        var r = val.toInt();

        val0 = getGreen(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = sqrt(re * re + im * im);
        var g = val.toInt();

        val0 = getBlue(c) / sqrt2;
        re = (val0 + nsigma * grand(random));
        im = (val0 + nsigma * grand(random));
        val = sqrt(re * re + im * im);
        var b = val.toInt();

        var a = getAlpha(c);
        image[i] = getColor(r, g, b, a);
      }
      break;
  }

  return image;
}
