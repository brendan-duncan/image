part of image;

/**
 * A [ExrFrameBuffer] stores an hdr image decoded from a part in an exr file.
 *
 * A framebuffer contains a set of slices. A slice is the pixel data for a
 * single channel. A framebuffer doesn't necessarily have to store image data;
 * it can also store other data such as depth buffers, index maps, etc.
 */
class ExrFrameBuffer {
  /// Stores all of the slices in the framebuffer, indexed by channel name.
  Map<String, ExrSlice> slices = {};
  /// Direct access to the red channel slice, if available.
  ExrSlice red;
  /// Direct access to the green channel slice, if available.
  ExrSlice green;
  /// Direct access to the blue channel slice, if available.
  ExrSlice blue;
  /// Direct access to the alpha channel slice, if available.
  ExrSlice alpha;

  /**
   * Does the framebuffer contain the given channel?
   */
  bool contains(String channel) => slices.containsKey(channel);

  /**
   * Access a framebuffer slice by name.
   */
  ExrSlice operator[](String ch) => slices[ch];

  /**
   * Add a slice to the framebuffer.
   */
  operator[]=(String ch, ExrSlice sl) {
    slices[ch] = sl;
    switch (sl.channel.name) {
      case ExrChannel.R:
        red = sl;
        break;
      case ExrChannel.G:
        green = sl;
        break;
      case ExrChannel.B:
        blue = sl;
        break;
      case ExrChannel.A:
        alpha = sl;
        break;
    }
  }

  /**
   * The width of the framebuffer.
   */
  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  /**
   * The height of the framebuffer.
   */
  int get height => slices.isEmpty ? 0 : slices.values.first.height;

  /**
   * Convert the framebuffer to an floating-point image, as a sequence of
   * floats in RGBA order.
   */
  Float32List toFloatRgba() {
    Float32List rgba = new Float32List(width * height * 4);
    int w = width;
    int h = height;
    for (int y = 0, di = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        rgba[di++] = red == null ? 0.0 : red.getFloatSample(x, y);
        rgba[di++] = green == null ? 0.0 : green.getFloatSample(x, y);
        rgba[di++] = blue == null ? 0.0 : blue.getFloatSample(x, y);
        rgba[di++] = alpha == null ? 0.0 : alpha.getFloatSample(x, y);
      }
    }

    return rgba;
  }
}
