import 'dart:math';

import 'hdr_image.dart';

/**
 * Applies Reinhard tone mapping to the hdr image, in-place.
 */
HdrImage reinhardToneMap(HdrImage hdr) {
  const List<double> yw = const [0.212671, 0.715160, 0.072169];

  // Compute world adaptation luminance, _Ywa_
  double Ywa = 0.0;
  for (int y = 0; y < hdr.height; ++y) {
    for (int x = 0; x < hdr.width; ++x) {
      double r = hdr.getRed(x, y);
      double g = hdr.getGreen(x, y);
      double b = hdr.getBlue(x, y);

      double lum = yw[0] * r + yw[1] * g + yw[2] * b;
      if (lum > 1.0e-4) {
        Ywa += log(lum);
      }
    }
  }

  Ywa = exp(Ywa / (hdr.width * hdr.height));

  double invY2 = 1.0 / (Ywa * Ywa);

  for (int y = 0; y < hdr.height; ++y) {
    for (int x = 0; x < hdr.width; ++x) {
      double r = hdr.getRed(x, y);
      double g = hdr.getGreen(x, y);
      double b = hdr.getBlue(x, y);

      double lum = yw[0] * r + yw[1] * g + yw[2] * b;

      double s = (1.0 + lum * invY2) / (1.0 + lum);

      hdr.setRed(x, y, r * s);
      hdr.setGreen(x, y, g * s);
      hdr.setBlue(x, y, b * s);
    }
  }

  return hdr;
}
