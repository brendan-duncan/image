import '../image/image.dart';

/// Add the [red], [green], [blue] and [alpha] values to the [src] image
/// colors, a per-channel brightness.
Image colorOffset(Image src,
    { num red = 0, num green = 0, num blue = 0, num alpha = 0 }) {
  for (final frame in src.frames) {
    for (final p in frame) {
      p..r += red
      ..g += green
      ..b += blue
      ..a += alpha;
    }
  }
  return src;
}
