// @dart=2.11
import 'dart:math';

import 'hdr_image.dart';

/// Applies Reinhard tone mapping to the hdr image, in-place.
HdrImage reinhardToneMap(HdrImage hdr) {
  const yw = [0.212671, 0.715160, 0.072169];

  // Compute world adaptation luminance, _Ywa_
  var Ywa = 0.0;
  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      var r = hdr.getRed(x, y);
      var g = hdr.getGreen(x, y);
      var b = hdr.getBlue(x, y);

      var lum = yw[0] * r + yw[1] * g + yw[2] * b;
      if (lum > 1.0e-4) {
        Ywa += log(lum);
      }
    }
  }

  Ywa = exp(Ywa / (hdr.width * hdr.height));

  var invY2 = 1.0 / (Ywa * Ywa);

  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      var r = hdr.getRed(x, y);
      var g = hdr.getGreen(x, y);
      var b = hdr.getBlue(x, y);

      var lum = yw[0] * r + yw[1] * g + yw[2] * b;

      var s = (1.0 + lum * invY2) / (1.0 + lum);

      hdr.setRed(x, y, r * s);
      hdr.setGreen(x, y, g * s);
      hdr.setBlue(x, y, b * s);
    }
  }

  return hdr;
}
