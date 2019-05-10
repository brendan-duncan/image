import '../image.dart';
import '../internal/clamp.dart';

/// Add the [red], [green], [blue] and [alpha] values to the [src] image
/// colors, a per-channel brightness.
Image colorOffset(Image src, int red, int green, int blue, int alpha) {
  var pixels = src.getBytes();
  for (int i = 0, len = pixels.length; i < len; i += 4) {
    pixels[i] = clamp255(pixels[i] + red);
    pixels[i + 1] = clamp255(pixels[i + 1] + green);
    pixels[i + 2] = clamp255(pixels[i + 2] + blue);
    pixels[i + 3] = clamp255(pixels[i + 3] + alpha);
  }

  return src;
}
