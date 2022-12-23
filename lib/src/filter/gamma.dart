import 'dart:math';

import '../image/image.dart';

/// Apply gamma scaling to the HDR image, in-place.
Image gamma(Image src, { num gamma = 2.2 }) {
  for (final frame in src.frames) {
    for (final p in frame) {
      p..r = pow(p.r, 1.0 / gamma)
      ..g = pow(p.g, 1.0 / gamma)
      ..b = pow(p.b, 1.0 / gamma);
    }
  }
  return src;
}
