part of dart_image;

/**
 * A 32-bit image buffer where pixels are encoded into 32-bit unsigned ints.
 * You can use the methods in color to encode/decode the RGBA channels of a
 * color for a pixel.
 */
class Image {
  final int width;
  final int height;
  /// Pixels are encoded into 4-byte integers, where each byte is an RGBA
  /// channel.
  final Data.Uint32List buffer;

  /**
   * Create an image with the given dimensions and format.
   */
  Image(int width, int height) :
    this.width = width,
    this.height = height,
    buffer = new Data.Uint32List(width * height) {
      if (width <= 0 || height <= 0) {
        throw new Exception('Invalid image format');
      }
    }

  /**
   * Create a copy of the image [other].
   */
  Image.from(Image other) :
    width = other.width,
    height = other.height,
    buffer = new Data.Uint32List.fromList(other.buffer);


  /**
   * Returns a resized copy of the image.  This currently does not do any
   * interpolation or multi-sampling.
   */
  Image resized(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw new Exception('Invalid size');
    }

    Image newImage = new Image(width, height);

    double dy = this.height / height;
    double dx = this.width / width;

    // Copy the pixels from this image to the new image.
    for (int y = 0; y < height; ++y) {
      int y2 = (y * dy).toInt();
      for (int x = 0; x < width; ++x) {
        int x2 = (x * dx).toInt();
        newImage.setPixel(x, y, getPixel(x2, y2));
      }
    }

    return newImage;
  }

  /**
   * Get the pixel from the given [x], [y] coordinate.
   */
  int getPixel(int x, int y) =>
    buffer[y * width + x];

  /**
   * Set the pixel at the given [x], [y] coordinate to the [color].
   */
  void setPixel(int x, int y, int color) {
    buffer[y * width + x] = color;
  }

  void setPixelRGBA(int x, int y, int r, int g, int b, [int a = 255]) {
    buffer[y * width + x] = color(r, g, b, a);
  }
}
