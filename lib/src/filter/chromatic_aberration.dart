import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '_frame_copy.dart';

/// Apply chromatic aberration filter to the image.
Image chromaticAberration(Image src,
    {int shift = 5, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  Image? scratch;
  for (final frame in src.frames) {
    scratch = copyFrameReusing(frame, scratch);
    final orig = scratch;
    final w = frame.width - 1;
    for (final p in frame) {
      final shiftLeft = (p.x - shift).clamp(0, w);
      final shiftRight = (p.x + shift).clamp(0, w);
      final lc = orig.getPixel(shiftLeft, p.y);
      final rc = orig.getPixel(shiftRight, p.y);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);

      if (msk == null) {
        p
          ..r = rc.r
          ..b = lc.b;
      } else {
        p
          ..r = mix(p.r, rc.r, msk)
          ..b = mix(p.b, lc.b, msk);
      }
    }
  }
  return src;
}
