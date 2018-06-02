import '../image.dart';
import 'flip.dart';
import 'copy_rotate.dart';

/**
 * If [image] has an orientation value in its exif data, this will rotate the
 * image so that it physically matches its orientation. This can be used to
 * bake the orientation of the image for image formats that don't support exif
 * data.
 */
Image bakeOrientation(Image image) {
  if (!image.exif.hasOrientation || image.exif.orientation == 1) {
    return new Image.from(image);
  }
  switch (image.exif.orientation) {
    case 2:
      return flipHorizontal(image);
    case 3:
      return flip(image, FLIP_BOTH);
    case 4:
      return flipHorizontal(copyRotate(image, 180));
    case 5:
      return flipHorizontal(copyRotate(image, 90));
    case 6:
      return copyRotate(image, 90);
    case 7:
      return flipHorizontal(copyRotate(image, -90));
    case 8:
      return copyRotate(image, -90);
  }
  return new Image.from(image);
}
