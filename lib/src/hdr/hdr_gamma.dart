import 'dart:math' as math;

import 'hdr_image.dart';

/// Apply gamma scaling to the HDR image, in-place.
HdrImage hdrGamma(HdrImage hdr, {double gamma: 2.2}) {
  for (int y = 0; y < hdr.height; ++y) {
    for (int x = 0; x < hdr.width; ++x) {
      var r = math.pow(hdr.getRed(x, y), 1.0 / gamma);
      var g = math.pow(hdr.getGreen(x, y), 1.0 / gamma);
      var b = math.pow(hdr.getBlue(x, y), 1.0 / gamma);

      hdr.setRed(x, y, r);
      hdr.setGreen(x, y, g);
      hdr.setBlue(x, y, b);
    }
  }

  return hdr;
}
