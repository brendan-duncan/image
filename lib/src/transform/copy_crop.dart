import '../image/image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src, int x, int y, int w, int h) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1).toInt();
  y = y.clamp(0, src.height - 1).toInt();
  if (x + w > src.width) {
    w = src.width - x;
  }
  if (y + h > src.height) {
    h = src.height - y;
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = firstFrame?.addFrame() ?? Image.fromResized(frame, w, h);
    firstFrame ??= dst;
    for (var p in dst) {
      p.set(frame.getPixel(x + p.x, y + p.y));
    }
  }

  return firstFrame!;
}
