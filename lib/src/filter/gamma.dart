import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '_rgb_lut.dart';

/// Apply gamma scaling
Image gamma(Image src,
    {required num gamma,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    if (mask == null &&
        frame.format == Format.uint8 &&
        frame.numChannels >= 3) {
      // Each channel only depends on itself, so a lookup table computed the
      // same way as the Pixel setters gives the same result.
      final lut = Uint8List(256);
      for (var v = 0; v < 256; ++v) {
        lut[v] = (pow(v / 255, gamma) * 255).clamp(0, 255).toInt();
      }
      applyRgbLut(frame, lut, lut, lut);
      continue;
    }
    for (final p in frame) {
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..rNormalized = pow(p.rNormalized, gamma)
          ..gNormalized = pow(p.gNormalized, gamma)
          ..bNormalized = pow(p.bNormalized, gamma);
      } else {
        p
          ..rNormalized = mix(p.rNormalized, pow(p.rNormalized, gamma), msk)
          ..gNormalized = mix(p.gNormalized, pow(p.gNormalized, gamma), msk)
          ..bNormalized = mix(p.bNormalized, pow(p.bNormalized, gamma), msk);
      }
    }
  }
  return src;
}
