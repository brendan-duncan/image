import '../exif/exif_data.dart';
import '../image/image.dart';
import 'copy_rotate.dart';
import 'flip.dart';

/// If [image] has an orientation value in its exif data, this will rotate the
/// image so that it physically matches its orientation. This can be used to
/// bake the orientation of the image for image formats that don't support exif
/// data.
Image bakeOrientation(Image image) {
  if (!image.exif.imageIfd.hasOrientation ||
      image.exif.imageIfd.orientation == 1) {
    return Image.from(image);
  }

  // Rotations make a new image, so they read straight from [image]; flips
  // work in place, on a copy.
  final orientation = image.exif.imageIfd.orientation;
  final Image baked;
  switch (orientation) {
    case 2:
      baked = flipHorizontal(Image.from(image));
      break;
    case 3:
      baked = flip(Image.from(image), direction: FlipDirection.both);
      break;
    case 4:
      // Rotating 180 degrees and flipping horizontally is a vertical flip.
      baked = flipVertical(Image.from(image));
      break;
    case 5:
      baked = flipHorizontal(copyRotate(image, angle: 90));
      break;
    case 6:
      baked = copyRotate(image, angle: 90);
      break;
    case 7:
      baked = flipHorizontal(copyRotate(image, angle: -90));
      break;
    case 8:
      baked = copyRotate(image, angle: -90);
      break;
    default:
      baked = Image.from(image);
      break;
  }

  // Copy all exif data except for orientation
  baked.exif = ExifData.from(image.exif);
  baked.exif.imageIfd.orientation = null;
  return baked;
}
