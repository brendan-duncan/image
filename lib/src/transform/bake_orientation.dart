import '../image.dart';
import '../exif_data.dart';
import 'flip.dart';
import 'copy_rotate.dart';

/**
 * If [image] has an orientation value in its exif data, this will rotate the
 * image so that it physically matches its orientation. This can be used to
 * bake the orientation of the image for image formats that don't support exif
 * data.
 */
Image bakeOrientation(Image image) {
  Image bakedImage = new Image.from(image);
  if (!image.exif.hasOrientation || image.exif.orientation == 1) {
    return bakedImage;
  }

  // Clear the exif data.
  // TODO: only clear the orientation property
  bakedImage.exif = new ExifData();
  switch (image.exif.orientation) {
    case 2:
      return flipHorizontal(bakedImage);
    case 3:
      return flip(bakedImage, FLIP_BOTH);
    case 4:
      return flipHorizontal(copyRotate(bakedImage, 180));
    case 5:
      return flipHorizontal(copyRotate(bakedImage, 90));
    case 6:
      return copyRotate(bakedImage, 90);
    case 7:
      return flipHorizontal(copyRotate(bakedImage, -90));
    case 8:
      return copyRotate(bakedImage, -90);
  }
  return bakedImage;
}
