part of image;

/**
 * A high dynamic range RGBA image stored in 16-bit or 32-bit floating-point
 * channels.
 */
class HdrImage {
  static const int HALF = 1;
  static const int FLOAT = 2;
  static const int UINT = 0;

  /// Red value of a sample
  static const String R = 'R';
  /// Green value of a sample
  static const String G = 'G';
  /// Blue value of a sample
  static const String B = 'B';
  /// Alpha/opacity
  static const String A = 'A';
  /// Distance of the front of a sample from the viewer
  static const String Z = 'Z';
  /// A numerical identifier for the object represented by a sample.
  static const String ID = 'id';

  final Map<String, HdrSlice> slices = {};
  HdrSlice red;
  HdrSlice green;
  HdrSlice blue;
  HdrSlice alpha;
  HdrSlice depth;

  HdrImage() {
  }

  /**
   * Create a copy of the [other] HdrImage.
   */
  HdrImage.from(HdrImage other) {
    for (String ch in other.slices.keys) {
      HdrSlice slice = other.slices[ch];
      addSlice(ch, new HdrSlice.from(slice));
    }
  }

  bool get hasColor => red != null || green != null || blue != null;

  bool get hasAlpha => alpha != null;

  bool get hasDepth => depth != null;

  /**
   * The width of the framebuffer.
   */
  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  /**
   * The height of the framebuffer.
   */
  int get height => slices.isEmpty ? 0 : slices.values.first.height;

  double getRed(int x, int y) {
    return red != null ? red.getFloat(x, y) : 0.0;
  }

  void setRed(int x, int y, double c) {
    if (red != null) {
      red.setFloat(x, y, c);
    }
  }

  double getGreen(int x, int y) {
    return green != null ? green.getFloat(x, y) : 0.0;
  }

  void setGreen(int x, int y, double c) {
    if (green != null) {
      green.setFloat(x, y, c);
    }
  }

  double getBlue(int x, int y) {
    return blue != null ? blue.getFloat(x, y) : 0.0;
  }

  void setBlue(int x, int y, double c) {
    if (blue != null) {
      blue.setFloat(x, y, c);
    }
  }

  double getAlpha(int x, int y) {
    return alpha != null ? alpha.getFloat(x, y) : 0.0;
  }

  void setAlpha(int x, int y, double c) {
    if (alpha != null) {
      alpha.setFloat(x, y, c);
    }
  }

  double getDepth(int x, int y) {
    return depth != null ? depth.getFloat(x, y) : 0.0;
  }

  void setDepth(int x, int y, double c) {
    if (depth != null) {
      depth.setFloat(x, y, c);
    }
  }

  /**
   * Does this image contain the given channel?
   */
  bool hasChannel(String ch) => slices.containsKey(ch);

  /**
   * Access a framebuffer slice by name.
   */
  HdrSlice operator[](String ch) => slices[ch];

  /**
   * Add a slice to the framebuffer.
   */
  operator[]=(String ch, HdrSlice sl) {
    addSlice(ch, sl);
  }

  void addSlice(String ch, HdrSlice sl) {
    slices[ch] = sl;
    switch (ch) {
      case R:
        red = sl;
        break;
      case G:
        green = sl;
        break;
      case B:
        blue = sl;
        break;
      case A:
        alpha = sl;
        break;
      case Z:
        depth = sl;
        break;
    }
  }

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
        rgba[di++] = red == null ? 0.0 : red.getFloat(x, y);
        rgba[di++] = green == null ? 0.0 : green.getFloat(x, y);
        rgba[di++] = blue == null ? 0.0 : blue.getFloat(x, y);
        rgba[di++] = alpha == null ? 1.0 : alpha.getFloat(x, y);
      }
    }

    return rgba;
  }
}

