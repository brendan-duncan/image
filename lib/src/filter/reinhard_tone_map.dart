import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Applies Reinhard tone mapping to the hdr image, in-place.
///
/// This is the global operator of Reinhard et al., "Photographic Tone
/// Reproduction for Digital Images". Luminance is scaled so the log-average
/// maps to a key of 0.18, then compressed by L * (1 + L / Lwhite^2) / (1 + L),
/// where Lwhite is the largest scaled luminance, so the luminance of the
/// result is in the 0-1 range.
Image reinhardTonemap(Image hdr,
    {Image? mask, Channel maskChannel = Channel.luminance}) {
  const yw = [0.212671, 0.715160, 0.072169];
  const key = 0.18;

  // Compute world adaptation luminance, _Ywa_, and the max luminance
  var ywa = 0.0;
  var yMax = 0.0;
  for (final p in hdr) {
    final r = p.r;
    final g = p.g;
    final b = p.b;
    final lum = yw[0] * r + yw[1] * g + yw[2] * b;
    if (lum > 1.0e-4) {
      ywa += log(lum);
    }
    if (lum > yMax) {
      yMax = lum;
    }
  }

  if (yMax <= 0.0) {
    return hdr;
  }

  ywa = exp(ywa / (hdr.width * hdr.height));

  // Scale luminance so the log-average maps to the key, and map the largest
  // scaled luminance to white.
  final lumScale = key / ywa;
  final white = yMax * lumScale;
  final invY2 = 1.0 / (white * white);

  for (final p in hdr) {
    final r = p.r;
    final g = p.g;
    final b = p.b;

    final lum = yw[0] * r + yw[1] * g + yw[2] * b;

    final ys = lum * lumScale;
    final s = lumScale * (1.0 + ys * invY2) / (1.0 + ys);

    final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
    if (msk == null) {
      p
        ..r = r * s
        ..g = g * s
        ..b = b * s;
    } else {
      p
        ..r = mix(p.r, r * s, msk)
        ..g = mix(p.g, g * s, msk)
        ..b = mix(p.b, b * s, msk);
    }
  }

  return hdr;
}
