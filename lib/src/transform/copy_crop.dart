import '../image/image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src, { required int x, required int y, required int width,
    required int height }) {
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
        Image.fromResized(frame, width: width, height: height,
            noAnimation: true);
    firstFrame ??= dst;
    for (final p in dst) {
      p.set(frame.getPixel(x + p.x, y + p.y));
    }
  }

  return firstFrame!;
}
