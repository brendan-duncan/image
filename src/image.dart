part of gd;

/**
 * An image buffer.
 */
class Image {
  static const int RGB = 3;
  static const int RGBA = 4;

  final int width;
  final int height;
  final int bytesPerPixel;
  /// Pixels are encoded into 4-byte integers.
  final Data.Uint32List buffer;

  /**
   * Create an image with the given dimensions and format.
   */
  Image(int width, int height, this.bytesPerPixel) :
    this.width = width,
    this.height = height,
    buffer = new Data.Uint32List(width * height) {
      if (width <= 0 || height <= 0 || bytesPerPixel < 3 || bytesPerPixel > 4) {
        throw new Exception('Invalid image format');
      }
    }

  /**
   * Create a copy of the image [other].
   */
  Image.from(Image other) :
    width = other.width,
    height = other.height,
    bytesPerPixel = other.bytesPerPixel,
    buffer = new Data.Uint32List.fromList(other.buffer);


  /**
   * Returns a resized copy of the image.  This currently does not do any
   * interpolation or multi-sampling.
   */
  Image resized(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw new Exception('Invalid size');
    }

    Image newImage = new Image(width, height, bytesPerPixel);

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

  static int color(int r, int g, int b, [int a = 255]) {
    return ((r & 0xFF) << 24) |
           ((g & 0xFF) << 16) |
           ((b & 0xFF) << 8) |
           (a & 0xFF);
  }

  static int red(int c) =>
      (c >> 24) & 0xFF;

  static int green(int c) =>
      (c >> 16) & 0xFF;

  static int blue(int c) =>
      (c >> 8) & 0xFF;

  static int alpha(int c) =>
      c & 0xFF;

  void setPixelRGBA(int x, int y, int r, int g, int b, [int a = 255]) {
    buffer[y * width + x] = color(r, g, b, a);
  }
}
