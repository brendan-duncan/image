import '../image/image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src,
    {required int x,
    required int y,
    required int width,
    required int height,
    num radius = 0}) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1).toInt();
  y = y.clamp(0, src.height - 1).toInt();
  if (x + width > src.width) {
    width = src.width - x;
  }
  if (y + height > src.height) {
    height = src.height - y;
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame,
            width: width, height: height, noAnimation: true);
    firstFrame ??= dst;

    if (radius > 0) {
      final rad = radius.round();
      final rad2 = rad * rad;
      final x1 = x;
      final y1 = y;
      final x2 = x + width - 1;
      final y2 = y + height - 1;
      final c1x = x1 + rad;
      final c1y = y1 + rad;
      final c2x = x2 - rad;
      final c2y = y1 + rad;
      final c3x = x2 - rad;
      final c3y = y2 - rad;
      final c4x = x1 + rad;
      final c4y = y2 - rad;

      final iter = src.getRange(x1, y1, width, height);
      while (iter.moveNext()) {
        final p = iter.current;
        final px = p.x;
        final py = p.y;
        if (px < c1x && py < c1y) {
          final dx = px - c1x;
          final dy = py - c1y;
          final d2 = dx * dx + dy * dy;
          if (d2 > rad2) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px > c2x && py < c2y) {
          final dx = px - c2x;
          final dy = py - c2y;
          final d2 = dx * dx + dy * dy;
          if (d2 > rad2) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px > c3x && py > c3y) {
          final dx = px - c3x;
          final dy = py - c3y;
          final d2 = dx * dx + dy * dy;
          if (d2 > rad2) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px < c4x && py > c4y) {
          final dx = px - c4x;
          final dy = py - c4y;
          final d2 = dx * dx + dy * dy;
          if (d2 > rad2) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        }

        dst.setPixel(p.x - x1, p.y - y1, frame.getPixel(p.x, p.y));
      }
    } else {
      for (final p in dst) {
        p.set(frame.getPixel(x + p.x, y + p.y));
      }
    }
  }

  return firstFrame!;
}
