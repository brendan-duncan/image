import '../color/color.dart';
import '../image/image.dart';

/// Set all of the pixels of an [image] to the given [color].
void fill(Image image, Color color) {
  image.clear(color);
}
