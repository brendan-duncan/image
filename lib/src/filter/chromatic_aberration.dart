import '../image/image.dart';

///
Image chromaticAberration(Image src, { int shift = 5 }) {
  for (final frame in src.frames) {
    final orig = frame.clone(noAnimation: true);
    final w = frame.width - 1;
    for (final p in frame) {
      final shiftLeft = (p.x - shift).clamp(0, w);
      final shiftRight = (p.x + shift).clamp(0, w);
      final lc = orig.getPixel(shiftLeft, p.y);
      final rc = orig.getPixel(shiftRight, p.y);
      p..r = rc.r
      ..b = lc.b;
    }
  }
  return src;
}
