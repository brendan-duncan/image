import '../color/channel.dart';
import '../image/image.dart';

/// Use the [mask] image to set the alpha channel of the [src] image.
/// [maskChannel] determines which channel of the [mask] image to use, or
/// the luminance (grayscale) of the mask image. If [scaleMask] is true,
/// and [mask] is a different resolution than [src], [mask] will be scaled
/// to the resolution of [src].
Image maskAlpha(Image src, Image mask,
    { Channel maskChannel = Channel.luminance, bool scaleMask = false }) {
  final dx = mask.width / src.width;
  final dy = mask.height / src.height;
  final maskPixel = mask.getPixel(0, 0);
  for (final frame in src.frames) {
    for (final p in frame) {
      if (scaleMask) {
        maskPixel.setPosition((p.x * dx).floor(), (p.y * dy).floor());
      } else {
        maskPixel.setPosition(p.x, p.y);
      }

      if (maskChannel == Channel.luminance) {
        final lr = maskPixel.r * 0.2125;
        final lg = maskPixel.g * 0.7154;
        final lb = maskPixel.b * 0.0721;
        final l = lr + lg + lb;
        p.a = l * maskPixel.a;
      } else {
        final m = maskPixel[maskChannel.index];
        if (maskChannel == Channel.alpha) {
          p.a = m;
        } else {
          p.a = m * maskPixel.a;
        }
      }
    }
  }
  return src;
}
