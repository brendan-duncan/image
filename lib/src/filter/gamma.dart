import 'dart:math';

import '../image/image.dart';

/// Apply gamma scaling to the HDR image, in-place.
Image gamma(Image hdr, { num gamma = 2.2 }) {
  for (var p in hdr) {
    p..r = pow(p.r, 1.0 / gamma)
    ..g = pow(p.r, 1.0 / gamma)
    ..b = pow(p.r, 1.0 / gamma);
  }
  return hdr;
}
