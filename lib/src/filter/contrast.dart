import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

num? _lastContrast;
late Uint8List _contrast;

enum ContrastMode { proportional, scurve }

/// Set the [contrast] level for the image [src].
///
/// [contrast] values below 100 will decrease the contrast of the image,
/// and values above 100 will increase the contrast. A contrast of 100
/// will have no affect.

Image contrast(Image src,
    {required num contrast,
    Image? mask,
    Channel maskChannel = Channel.luminance,
    ContrastMode mode = ContrastMode.proportional}) {
  if (contrast == 100.0) {
    return src;
  }
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  if (mode == ContrastMode.proportional) {
    if (contrast != _lastContrast) {
      _lastContrast = contrast;

      contrast = contrast / 100.0;
      contrast = contrast * contrast;
      _contrast = Uint8List(256);
      for (var i = 0; i < 256; ++i) {
        _contrast[i] = (((((i / 255.0) - 0.5) * contrast) + 0.5) * 255.0)
            .clamp(0, 255)
            .toInt();
      }
    } else {
      if (contrast != _lastContrast) {
        _lastContrast = contrast;

        /// 0.12 is an arbitrary adjustment to use 100 as mid point
        contrast = (contrast / 100.0) - 0.12;
        _contrast = Uint8List(256);
        for (var i = 0; i < 256; ++i) {
          _contrast[i] =
              (((tan(((i / 128) - 1) * contrast) + 1.0) / 2.0) * 255.0)
                  .clamp(0, 255)
                  .toInt();
        }
      }
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
