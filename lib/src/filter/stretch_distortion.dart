import '../image/image.dart';
import '../util/interpolation.dart';
import '../util/math_util.dart';

Image stretchDistortion(Image src, { int? centerX, int? centerY,
    Interpolation interpolation = Interpolation.nearest }) {
  for (final frame in src.frames) {
    final orig = frame.clone(noAnimation: true);
    final w = frame.width - 1;
    final h = frame.height - 1;
    final cx = centerX ?? frame.width ~/ 2;
    final cy = centerY ?? frame.height ~/ 2;
    final nCntX = 2 * (cx / w) - 1;
    final nCntY = 2 * (cy / h) - 1;
    for (final p in frame) {
      var ncX = (p.x / w) * 2 - 1;
      var ncY = (p.y / h) * 2 - 1;
      ncX -= nCntX;
      ncY -= nCntY;
      final sX = sign(ncX);
      final sY = sign(ncY);
      ncX = ncX.abs();
      ncY = ncY.abs();
      ncX = (0.5 * ncX + 0.5 * smoothstep(0.25, 0.5, ncX) * ncX) * sX;
      ncY = (0.5 * ncY + 0.5 * smoothstep(0.25, 0.5, ncY) * ncY) * sY;
      ncX += nCntX;
      ncY += nCntY;

      final x = ((ncX / 2 + 0.5) * w).clamp(0, w - 1);
      final y = ((ncY / 2 + 0.5) * h).clamp(0, h - 1);

      final p2 = orig.getPixelInterpolate(x, y, interpolation: interpolation);

      p..r = p2.r
      ..g = p2.g
      ..b = p2.b;
    }
  }
  return src;
}
