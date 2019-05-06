import 'dart:typed_data';

import '../image.dart';
import 'hdr_slice.dart';

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
   * Create an RGB[A] image.
   */
  HdrImage.create(int width, int height, int channels, int format) {
    if (channels < 0 || channels > 4) {
      return;
    }
    if (format != HALF && format != FLOAT && format != UINT) {
      return;
    }

    const List<String> channelList = const [R, G, B, A];
    for (int i = 0; i < channels; ++i) {
      addSlice(new HdrSlice(channelList[i], width, height, format));
    }
  }

  /**
   * Create a copy of the [other] HdrImage.
   */
  HdrImage.from(HdrImage other) {
    for (String ch in other.slices.keys) {
      HdrSlice slice = other.slices[ch];
      addSlice(new HdrSlice.from(slice));
    }
  }

  /**
   * Create an HDR image from a LDR [Image] by transforming the channel values
   * to the range [0, 1].
   */
  HdrImage.fromImage(Image other) {
    addSlice(new HdrSlice(R, other.width, other.height, HALF));
    addSlice(new HdrSlice(G, other.width, other.height, HALF));
    addSlice(new HdrSlice(B, other.width, other.height, HALF));
    if (other.format == Image.RGBA) {
      addSlice(new HdrSlice(A, other.width, other.height, HALF));
    }
    Uint8List rgb = other.getBytes();
    for (int y = 0, si = 0; y < other.height; ++y) {
      for (int x = 0; x < other.width; ++x) {
        red.setFloat(x, y, rgb[si++] / 255.0);
        green.setFloat(x, y, rgb[si++] / 255.0);
        blue.setFloat(x, y, rgb[si++] / 255.0);
        if (alpha != null) {
          alpha.setFloat(x, y, rgb[si++] / 255.0);
        }
      }
    }
  }

  /**
   * Does the image have any color channels?
   */
  bool get hasColor => red != null || green != null || blue != null;

  /**
   * Does the image have an alpha channel?
   */
  bool get hasAlpha => alpha != null;

  /**
   * Does the image have a depth channel?
   */
  bool get hasDepth => depth != null;

  /**
   * The width of the framebuffer.
   */
  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  /**
   * The height of the framebuffer.
   */
  int get height => slices.isEmpty ? 0 : slices.values.first.height;

  /**
   * Get the value of the red channel at the given pixel coordinates [x], [y].
   */
  double getRed(int x, int y) {
    return red != null ? red.getFloat(x, y) : 0.0;
  }

  /**
   * Set the value of the red channel at the given pixel coordinates [x], [y].
   */
  void setRed(int x, int y, double c) {
    if (red != null) {
      red.setFloat(x, y, c);
    }
  }

  void setRedInt(int x, int y, int c) {
    if (red != null) {
      red.setInt(x,  y, c);
    }
  }

  /**
   * Get the value of the green channel at the given pixel coordinates [x], [y].
   */
  double getGreen(int x, int y) {
    return green != null ? green.getFloat(x, y) : 0.0;
  }

  /**
   * Set the value of the green channel at the given pixel coordinates [x], [y].
   */
  void setGreen(int x, int y, double c) {
    if (green != null) {
      green.setFloat(x, y, c);
    }
  }

  void setGreenInt(int x, int y, int c) {
    if (green != null) {
      green.setInt(x,  y, c);
    }
  }

  /**
   * Get the value of the blue channel at the given pixel coordinates [x], [y].
   */
  double getBlue(int x, int y) {
    return blue != null ? blue.getFloat(x, y) : 0.0;
  }

  /**
   * Set the value of the blue channel at the given pixel coordinates [x], [y].
   */
  void setBlue(int x, int y, double c) {
    if (blue != null) {
      blue.setFloat(x, y, c);
    }
  }

  void setBlueInt(int x, int y, int c) {
    if (blue != null) {
      blue.setInt(x, y, c);
    }
  }

  /**
   * Get the value of the alpha channel at the given pixel coordinates [x], [y].
   */
  double getAlpha(int x, int y) {
    return alpha != null ? alpha.getFloat(x, y) : 0.0;
  }

  /**
   * Set the value of the alpha channel at the given pixel coordinates [x], [y].
   */
  void setAlpha(int x, int y, double c) {
    if (alpha != null) {
      alpha.setFloat(x, y, c);
    }
  }

  void setAlphaInt(int x, int y, int c) {
    if (alpha != null) {
      alpha.setInt(x, y, c);
    }
  }

  /**
   * Get the value of the depth channel at the given pixel coordinates [x], [y].
   */
  double getDepth(int x, int y) {
    return depth != null ? depth.getFloat(x, y) : 0.0;
  }

  /**
   * Set the value of the depth channel at the given pixel coordinates [x], [y].
   */
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
   * Add a channel [slice] to the
   */
  void addSlice(HdrSlice slice) {
    String ch = slice.name;
    slices[ch] = slice;
    switch (ch) {
      case R:
        red = slice;
        break;
      case G:
        green = slice;
        break;
      case B:
        blue = slice;
        break;
      case A:
        alpha = slice;
        break;
      case Z:
        depth = slice;
        break;
    }
  }

  /**
   * Convert the framebuffer to an floating-point image, as a sequence of
   * floats in RGBA order.
   */
  Float32List toFloatRgba() {
    Float32List rgba = Float32List(width * height * 4);
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

