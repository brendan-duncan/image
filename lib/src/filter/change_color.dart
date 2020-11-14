import '../image.dart';
import '../internal/clamp.dart';

/// Change the color of the [src] image.
///
/// [red] defines the red color of the image, as an integer (0 - 255).
///
/// [green] defines the green color of the image, as an integer (0 - 255).
///
/// [blue] defines the blue color of the image, as an integer (0 - 255).
Image changeColor(Image src, {int red, int green, int blue}) {
  var pixels = src.getBytes();

  for (var i = 0, len = pixels.length; i < len; i += 4) {
    pixels[i] = clamp255((red).toInt());
    pixels[i + 1] = clamp255((green).toInt());
    pixels[i + 2] = clamp255((blue).toInt());
  }

  return src;
}
