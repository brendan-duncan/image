import 'dart:math';

import '../image/image.dart';

/// Apply gamma scaling
Image gamma(Image src, { num gamma = 2.2 }) {
  for (final frame in src.frames) {
    for (final p in frame) {
      p..r = pow(p.r / p.maxChannelValue, gamma) * p.maxChannelValue
      ..g = pow(p.g / p.maxChannelValue, gamma) * p.maxChannelValue
      ..b = pow(p.b / p.maxChannelValue, gamma) * p.maxChannelValue;
    }
  }
  return src;
}
