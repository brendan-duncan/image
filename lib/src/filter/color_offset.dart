import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Add the [red], [green], [blue] and [alpha] values to the [src] image
/// colors, a per-channel brightness. The offsets are specified in 8-bit
/// terms and are scaled to the bit depth of the image, so the effect is
/// consistent regardless of the image's format.
Image colorOffset(Image src,
    {num red = 0,
    num green = 0,
    num blue = 0,
    num alpha = 0,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    for (final p in frame) {
      // Scale the 8-bit offsets to the bit depth of the image.
      final scale = p.maxChannelValue / 255.0;
      final r = red * scale;
      final g = green * scale;
      final b = blue * scale;
      final a = alpha * scale;
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..r += r
          ..g += g
          ..b += b
          ..a += a;
      } else {
        p
          ..r = mix(p.r, p.r + r, msk)
          ..g = mix(p.g, p.g + g, msk)
          ..b = mix(p.b, p.b + b, msk)
          ..a = mix(p.a, p.a + a, msk);
      }
    }
  }
  return src;
}
