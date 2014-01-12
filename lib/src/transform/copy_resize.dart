part of image;

/**
 * Returns a resized copy of the [src] image.
 * If [height] is -1, then it will be determined by the aspect
 * ratio of [src] and [width].
 */
Image copyResize(Image src, int width, [int height = -1,
                 int interpolation = CUBIC]) {
  if (height < 0) {
    height = (width * (src.height / src.width)).toInt();
  }

  if (width <= 0 || height <= 0) {
    throw new Exception('Invalid size');
  }

  Image newImage = new Image(width, height, src.format);

  double dy = src.height / height;
  double dx = src.width / width;

  // Copy the pixels from this image to the new image.
  switch (interpolation) {
    case CUBIC:
      for (int y = 0; y < height; ++y) {
        double y2 = (y * dy);
        for (int x = 0; x < width; ++x) {
          double x2 = (x * dx);
          newImage.setPixel(x, y, src.getPixelCubic(x2, y2));
        }
      }
      break;
    case LINEAR:
      for (int y = 0; y < height; ++y) {
        double y2 = (y * dy);
        for (int x = 0; x < width; ++x) {
          double x2 = (x * dx);
          newImage.setPixel(x, y, src.getPixelLinear(x2, y2));
        }
      }
      break;
    default:
      for (int y = 0; y < height; ++y) {
        int y2 = (y * dy).toInt();
        for (int x = 0; x < width; ++x) {
          int x2 = (x * dx).toInt();
          newImage.setPixel(x, y, src.getPixel(x2, y2));
        }
      }
  }

  return newImage;
}
