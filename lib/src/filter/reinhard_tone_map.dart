import 'dart:math';

import '../image/image.dart';

/// Applies Reinhard tone mapping to the hdr image, in-place.
Image reinhardTonemap(Image hdr) {
  const yw = [0.212671, 0.715160, 0.072169];

  // Compute world adaptation luminance, _Ywa_
  var ywa = 0.0;
  for (var p in hdr) {
    final r = p.r;
    final g = p.g;
    final b = p.b;
    final lum = yw[0] * r + yw[1] * g + yw[2] * b;
    if (lum > 1.0e-4) {
      ywa += log(lum);
    }
  }

  ywa = exp(ywa / (hdr.width * hdr.height));

  final invY2 = 1.0 / (ywa * ywa);

  for (var p in hdr) {
    final r = p.r;
    final g = p.g;
    final b = p.b;

    final lum = yw[0] * r + yw[1] * g + yw[2] * b;

    final s = (1.0 + lum * invY2) / (1.0 + lum);

    p..r = r * s
    ..g = g * s
    ..b = b * s;
  }

  return hdr;
}
