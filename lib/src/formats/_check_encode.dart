import '../image/image.dart';
import '../util/image_exception.dart';

/// Throws an [ImageException] if [image] has no pixels to encode.
void checkEncode(Image image) {
  if (image.width < 1 || image.height < 1 || image.data == null) {
    throw ImageException('Cannot encode an empty image');
  }
}
