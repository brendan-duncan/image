part of image;

/**
 * A 32-bit image buffer where pixels are encoded into 32-bit unsigned ints.
 * You can use the methods in color to encode/decode the RGBA channels of a
 * color for a pixel.
 */
class Image {
  static const int RGB = 3;
  static const int RGBA = 4;

  final int width;
  final int height;
  final int format;
  /// Pixels are encoded into 4-byte integers, where each byte is an RGBA
  /// channel.
  final Data.Uint32List buffer;

  /**
   * Create an image with the given dimensions and format.
   */
  Image(int width, int height, [this.format = RGBA]) :
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
    format = other.format,
    buffer = new Data.Uint32List.fromList(other.buffer);

  /**
   * Is the given pixel coordinates within the resolution of the image.
   */
  bool boundsSafe(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  /**
   * Get the pixel from the given [x], [y] coordinate.
   */
  int getPixel(int x, int y) =>
    boundsSafe(x, y) ?
      format == RGBA ?
        buffer[y * width + x] :
        buffer[y * width + x] | 0xff : 0;

  /**
   * Set the pixel at the given [x], [y] coordinate to the [color].
   */
  void setPixel(int x, int y, int color) {
    if (boundsSafe(x, y)) {
      buffer[y * width + x] = color;
    }
  }

  /**
   * Set the pixel with alpha blending.
   */
  void setPixelBlend(int x, int y, int color, [int fraction = 0xff]) {
    if (boundsSafe(x, y)) {
      int pi = y * width + x;
      int dst = buffer[pi];
      buffer[pi] = alphaBlendColors(dst, color, fraction);
    }
  }

  /**
   * Set the color of a pixel with no blending.
   */
  void setPixelRGBA(int x, int y, int r, int g, int b, [int a = 255]) {
    if (boundsSafe(x, y)) {
      buffer[y * width + x] = getColor(r, g, b, a);
    }
  }
}
