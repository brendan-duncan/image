import '../image/image.dart';

///
Image blackAndWhite(Image src, { num threshold = 0.5 }) {
  for (final frame in src.frames) {
    for (final p in frame) {
      final y = 0.3 * p.rNormalized +
          0.59 * p.gNormalized +
          0.11 * p.bNormalized;
      final y2 = y < threshold ? 0 : p.maxChannelValue;
      p..r = y2
      ..g = y2
      ..b = y2;
    }
  }
  return src;
}
