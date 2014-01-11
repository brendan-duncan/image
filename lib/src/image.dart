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
        throw new ImageException('Invalid image format');
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
   * Create an image from [bytes].
   *
   * [bytes] should be in RGB<A> format with a byte [0,255] for each channel.
   * The length of [bytes] should be <3|4> * (width * height).
   * [format] determines if there are 3 or 4 channels per pixel.
   *
   * For example, given an Html Canvas, you could create an image:
   * var bytes = canvas.getContext('2d').getImageData(0, 0,
   *   canvas.width, canvas.height);
   * Image image = new Image.fromBytes(canvas.width, canvas.height, bytes);
   */
  Image.fromBytes(int width, int height, List<int> bytes,
                  [this.format = RGBA]) :
    this.width = width,
    this.height = height,
    // Create a uint32 view of the byte buffer.
    buffer = new Data.Uint32List(width * height) {
    if (width <= 0 || height <= 0 || buffer.length != (width * height)) {
      throw new ImageException('Invalid image format');
    }
    // It would be nice if we could just create a Uint32List.view for the byte
    // buffer, but the channels would be in reverse order (endianness problem).
    final int len = buffer.length;
    final int inc = format == RGBA ? 4 : 3;
    for (int i = 0, j = 0; i < len; ++i, j += inc) {
      int a = format == RGBA ? bytes[j + 3] : 0xff;
      buffer[i] = getColor(bytes[j], bytes[j + 1], bytes[j + 2], a);
    }
  }

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
