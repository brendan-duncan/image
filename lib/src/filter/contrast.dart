import 'dart:typed_data';

import '../image/image.dart';

num? _lastContrast;
late Uint8List _contrast;

/// Set the [contrast] level for the image [src].
///
/// [contrast] values below 100 will decrees the contrast of the image,
/// and values above 100 will increase the contrast. A contrast of of 100
/// will have no affect.
Image? contrast(Image? src, num contrast) {
  if (src == null || contrast == 100.0) {
    return src;
  }

  if (contrast != _lastContrast) {
    _lastContrast = contrast;

    contrast = contrast / 100.0;
    contrast = contrast * contrast;
    _contrast = Uint8List(256);
    for (var i = 0; i < 256; ++i) {
      _contrast[i] = (((((i / 255.0) - 0.5) * contrast) + 0.5) * 255.0)
          .clamp(0, 255).toInt();
    }
  }

  for (final frame in src.frames) {
    for (final p in frame) {
      p..r = _contrast[p.r as int]
      ..g = _contrast[p.g as int]
      ..b = _contrast[p.b as int];
    }
  }

  return src;
}
