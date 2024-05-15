import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

num? _lastContrast;
late Uint8List _contrast;

Image contrast_s(Image src,
    {required num contrast,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (contrast == 100.0) {
    return src;
  }

  if (contrast != _lastContrast) {
    _lastContrast = contrast;

        contrast = (contrast / 100.0) - 0.12;
        _contrast = Uint8List(256);
    for (var i = 0; i < 256; ++i) {
      _contrast[i] = (((tan(((i / 127.5) - 1) * contrast) + 1.0) / 2.0) * 255.0)
          .clamp(0, 255)
          .toInt();
    }
  }

  for (final frame in src.frames) {
    for (final p in frame) {
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..r = _contrast[p.r as int]
          ..g = _contrast[p.g as int]
          ..b = _contrast[p.b as int];
      } else {
        p
          ..r = mix(p.r, _contrast[p.r as int], msk)
          ..g = mix(p.g, _contrast[p.g as int], msk)
          ..b = mix(p.b, _contrast[p.b as int], msk);
      }
    }
  }

  return src;
}
