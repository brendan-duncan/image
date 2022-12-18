import '../image/image.dart';

/// Add the [red], [green], [blue] and [alpha] values to the [src] image
/// colors, a per-channel brightness.
Image colorOffset(Image src,
    {int red = 0, int green = 0, int blue = 0, int alpha = 0}) {
  for (var p in src) {
    p.r += red;
    p.g += green;
    p.b += blue;
    p.a += alpha;
  }
  return src;
}
