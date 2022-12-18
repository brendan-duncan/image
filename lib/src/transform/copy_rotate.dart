import 'dart:math';

import '../image/image.dart';
import '../util/interpolation.dart';

/// Returns a copy of the [src] image, rotated by [angle] degrees.
Image copyRotate(Image src, num angle,
    { Interpolation interpolation = Interpolation.nearest }) {
  final num nAngle = angle % 360.0;

  // Optimized version for orthogonal angles.
  if ((nAngle % 90.0) == 0.0) {
    final wm1 = src.width - 1;
    final hm1 = src.height - 1;

    final iAngle = nAngle ~/ 90.0;
    switch (iAngle) {
      case 1: // 90 deg.
        final dst = Image(src.height, src.width,
            numChannels: src.numChannels, format: src.format,
            palette: src.palette, exif: src.exif, iccp: src.iccProfile);
        for (var y = 0; y < dst.height; ++y) {
          for (var x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(y, hm1 - x));
          }
        }
        return dst;
      case 2: // 180 deg.
        final dst = Image(src.width, src.height,
            numChannels: src.numChannels, format: src.format,
            palette: src.palette, exif: src.exif, iccp: src.iccProfile);
        for (var y = 0; y < dst.height; ++y) {
          for (var x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - x, hm1 - y));
          }
        }
        return dst;
      case 3: // 270 deg.
        final dst = Image(src.height, src.width,
            numChannels: src.numChannels, format: src.format,
            palette: src.palette, exif: src.exif, iccp: src.iccProfile);
        for (var y = 0; y < dst.height; ++y) {
          for (var x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - y, x));
          }
        }
        return dst;
      default: // 0 deg.
        return Image.from(src);
    }
  }

  // Generic angle.
  final rad = (nAngle * pi / 180.0);
  final ca = cos(rad);
  final sa = sin(rad);
  final ux = (src.width * ca).abs();
  final uy = (src.width * sa).abs();
  final vx = (src.height * sa).abs();
  final vy = (src.height * ca).abs();
  final w2 = 0.5 * src.width;
  final h2 = 0.5 * src.height;
  final dw2 = 0.5 * (ux + vx);
  final dh2 = 0.5 * (uy + vy);

  final dst = Image((ux + vx).toInt(), (uy + vy).toInt(),
      format: src.format, numChannels: src.numChannels, palette: src.palette,
      exif: src.exif, iccp: src.iccProfile);

  for (var p in dst) {
    final x = p.x;
    final y = p.y;
    final x2 = w2 + (x - dw2) * ca + (y - dh2) * sa;
    final y2 = h2 - (x - dw2) * sa + (y - dh2) * ca;
    final c = src.getPixelInterpolate(x2, y2, interpolation);
    dst.setPixel(x, y, c);
  }

  return dst;
}
