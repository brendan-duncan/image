import 'dart:math';
import 'dart:typed_data';

import 'color.dart';
import 'exif_data.dart';
import 'icc_profile_data.dart';
import 'util/interpolation.dart';

enum Format {
  argb,
  abgr,
  rgba,
  bgra,
  rgb,
  bgr,
  luminance
}

enum Channels {
  rgb,
  rgba
}

enum BlendMode {
  /// No alpha blending should be done when drawing this frame (replace
  /// pixels in canvas).
  source,
  /// Alpha blending should be used when drawing this frame (composited over
  /// the current canvas image).
  over
}

enum DisposeMode {
  /// When drawing a frame, the canvas should be left as it is.
  none,
  /// When drawing a frame, the canvas should be cleared first.
  clear,
  /// When drawing this frame, the canvas should be reverted to how it was
  /// before drawing it.
  previous
}

/// A 32-bit image buffer where pixels are encoded into 32-bit unsigned ints.
/// You can use the methods in color to encode/decode the RGBA channels of a
/// color for a pixel.
///
/// Pixels are stored in 32-bit unsigned integers in 0xAARRGGBB format.
/// This is to be consistent with the Flutter image data. You can use
/// [getBytes] to access the pixel data at the byte (channel) level, optionally
/// providing the format to get the image data as.
///
/// If this image is a frame of an animation as decoded by the [decodeFrame]
/// method of [Decoder], then the [xOffset], [yOffset], [width] and [height]
/// coordinates determine area of the canvas this image should be drawn into,
/// as some frames of an animation only modify part of the canvas (recording
/// the part of the frame that actually changes). The [decodeAnimation] method
/// will always return the fully composed animation, so these coordinate
/// properties are not used.
class Image {
  /// Width of the image.
  final int width;

  /// Height of the image.
  final int height;

  Channels channels;

  /// x position at which to render the frame.
  int xOffset = 0;

  /// y position at which to render the frame.
  int yOffset = 0;

  /// How long this frame should be displayed, in milliseconds.
  /// A duration of 0 indicates no delay and the next frame will be drawn
  /// as quickly as it can.
  int duration = 0;

  /// Defines what should be done to the canvas when drawing this frame.
  DisposeMode disposeMethod = DisposeMode.clear;

  /// Defines the blending method (alpha compositing) to use when drawing this
  /// frame.
  BlendMode blendMethod = BlendMode.over;

  /// Pixels are encoded into 4-byte integers, where each byte is an RGBA
  /// channel.
  final Uint32List data;
  ExifData exif;
  ICCProfileData iccProfile;

  /// Create an image with the given dimensions and format.
  Image(this.width, this.height,
        {this.channels = Channels.rgba, ExifData exif, ICCProfileData iccp})
      : this.data = Uint32List(width * height),
        this.exif = ExifData.from(exif),
        this.iccProfile = iccp;

  Image.rgb(this.width, this.height,
      {ExifData exif, ICCProfileData iccp})
      : this.channels = Channels.rgb,
        this.data = Uint32List(width * height),
        this.exif = ExifData.from(exif),
        this.iccProfile = iccp;

  /// Create a copy of the image [other].
  Image.from(Image other)
      : width = other.width,
        height = other.height,
        xOffset = other.xOffset,
        yOffset = other.yOffset,
        duration = other.duration,
        disposeMethod = other.disposeMethod,
        blendMethod = other.blendMethod,
        channels = other.channels,
        data = Uint32List.fromList(other.data),
        exif = ExifData.from(other.exif),
        iccProfile = other.iccProfile;

  /// Create an image from raw data in [bytes].
  ///
  /// [format] defines the order of color channels in [bytes].
  /// An HTML canvas element stores colors in Format.rgba format; a Flutter
  /// Image object stores colors in Format.bgra format.
  /// The length of [bytes] should be format-bytes[1,2,3,4] * (width * height).
  ///
  /// For example, given an Html Canvas, you could create an image:
  /// var bytes = canvas.getContext('2d').getImageData(0, 0,
  ///   canvas.width, canvas.height).data;
  /// var image = Image.fromBytes(canvas.width, canvas.height, bytes,
  ///                             format: Format.rgba);
  Image.fromBytes(int width, int height, List<int> bytes,
                 {ExifData exif, ICCProfileData iccp,
                 Format format = Format.bgra,
                 this.channels = Channels.rgba})
      : this.width = width,
        this.height = height,
        data = _convertData(width, height, bytes, format),
        exif = ExifData.from(exif),
        iccProfile = iccp;

  /// Clone this image.
  Image clone() => Image.from(this);

  /// The number of channels used by this Image.
  int get numberOfChannels => channels == Channels.rgba ? 4 : 3;

  /// Get the bytes from the image. You can use this to access the
  /// color channels directly, or to pass it to something like an
  /// Html canvas context.
  ///
  /// For example, given an Html Canvas, you could draw this image into the
  /// canvas:
  /// Html.ImageData d = context2D.createImageData(image.width, image.height);
  /// d.data.setRange(0, image.length, image.getBytes(format: Format.rgba));
  /// context2D.putImageData(data, 0, 0);
  Uint8List getBytes({Format format = Format.bgra}) {
    Uint8List bgra = Uint8List.view(data.buffer);
    switch (format) {
      case Format.bgra:
        return bgra;
      case Format.rgba:
        Uint8List bytes = Uint8List(width * height * 4);
        for (int i = 0, len = bytes.length; i < len; i += 4) {
          bytes[i + 0] = bgra[i + 2];
          bytes[i + 1] = bgra[i + 1];
          bytes[i + 2] = bgra[i + 0];
          bytes[i + 3] = bgra[i + 3];
        }
        return bytes;
      case Format.abgr:
        Uint8List bytes = Uint8List(width * height * 4);
        for (int i = 0, len = bytes.length; i < len; i += 4) {
          bytes[i + 0] = bgra[i + 3];
          bytes[i + 1] = bgra[i + 0];
          bytes[i + 2] = bgra[i + 1];
          bytes[i + 3] = bgra[i + 2];
        }
        return bytes;
      case Format.argb:
        Uint8List bytes = Uint8List(width * height * 4);
        for (int i = 0, len = bytes.length; i < len; i += 4) {
          bytes[i + 0] = bgra[i + 3];
          bytes[i + 1] = bgra[i + 2];
          bytes[i + 2] = bgra[i + 1];
          bytes[i + 3] = bgra[i + 0];
        }
        return bytes;
      case Format.rgb:
        Uint8List bytes = Uint8List(width * height * 3);
        for (int i = 0, j = 0, len = bytes.length; i < len; i += 4, j += 3) {
          bytes[j + 0] = bgra[i + 2];
          bytes[j + 1] = bgra[i + 1];
          bytes[j + 2] = bgra[i + 0];
        }
        return bytes;
      case Format.bgr:
        Uint8List bytes = Uint8List(width * height * 3);
        for (int i = 0, j = 0, len = bytes.length; i < len; i += 4, j += 3) {
          bytes[j + 0] = bgra[i + 0];
          bytes[j + 1] = bgra[i + 1];
          bytes[j + 2] = bgra[i + 2];
        }
        return bytes;
      case Format.luminance:
        Uint8List bytes = Uint8List(width * height);
        for (int i = 0, len = length; i < len; ++i) {
          bytes[i] = getLuminance(data[i]);
        }
        return bytes;
    }
    return bgra;
  }

  /// Set all of the pixels of the image to the given [color].
  Image fill(int color) {
    data.fillRange(0, data.length, color);
    return this;
  }

  /// Add the colors of [other] to the pixels of this image.
  Image operator +(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 + r2, g1 + g2, b1 + b2, a1 + a2));
      }
    }
    return this;
  }

  /// Subtract the colors of [other] from the pixels of this image.
  Image operator -(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 - r2, g1 - g2, b1 - b2, a1 - a2));
      }
    }
    return this;
  }

  /// Multiply the colors of [other] with the pixels of this image.
  Image operator *(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 * r2, g1 * g2, b1 * b2, a1 * a2));
      }
    }
    return this;
  }

  /// OR the colors of [other] to the pixels of this image.
  Image operator |(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 | r2, g1 | g2, b1 | b2, a1 | a2));
      }
    }
    return this;
  }

  /// AND the colors of [other] with the pixels of this image.
  Image operator &(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 & r2, g1 & g2, b1 & b2, a1 & a2));
      }
    }
    return this;
  }

  /// Modula the colors of [other] with the pixels of this image.
  Image operator %(Image other) {
    int h = min(height, other.height);
    int w = min(width, other.width);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        int c1 = getPixel(x, y);
        int r1 = getRed(c1);
        int g1 = getGreen(c1);
        int b1 = getBlue(c1);
        int a1 = getAlpha(c1);

        int c2 = other.getPixel(x, y);
        int r2 = getRed(c2);
        int g2 = getGreen(c2);
        int b2 = getBlue(c2);
        int a2 = getAlpha(c2);

        setPixel(x, y, getColor(r1 % r2, g1 % g2, b1 % b2, a1 % a2));
      }
    }
    return this;
  }

  /// The size of the image buffer.
  int get length => data.length;

  /// Get a pixel from the buffer.
  int operator [](int index) => data[index];

  /// Set a pixel in the buffer.
  void operator []=(int index, int color) {
    data[index] = color;
  }

  /// Get the buffer index for the [x], [y] pixel coordinates.
  int index(int x, int y) => y * width + x;

  /// Is the given pixel coordinates within the resolution of the image.
  bool boundsSafe(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  /// Get the pixel from the given [x], [y] coordinate. Color is encoded as
  /// #AARRGGBB.
  int getPixel(int x, int y) => data[y * width + x];

  /// Get the pixel from the given [x], [y] coordinate. Color is encoded as
  /// #AARRGGBB. If the pixel coordinates are out of bounds, 0 is returned.
  int getPixelSafe(int x, int y) => boundsSafe(x, y) ? data[y * width + x] : 0;

  /// Get the pixel using the given [interpolation] type for non-integer pixel
  /// coordinates.
  int getPixelInterpolate(num fx, num fy,
      [Interpolation interpolation = Interpolation.linear]) {
    if (interpolation == Interpolation.cubic) {
      return getPixelCubic(fx, fy);
    } else if (interpolation == Interpolation.linear) {
      return getPixelLinear(fx, fy);
    }
    return getPixelSafe(fx.toInt(), fy.toInt());
  }

  /// Get the pixel using linear interpolation for non-integer pixel
  /// coordinates.
  int getPixelLinear(num fx, num fy) {
    int x = fx.toInt() - (fx >= 0 ? 0 : 1);
    int nx = x + 1;
    int y = fy.toInt() - (fy >= 0 ? 0 : 1);
    int ny = y + 1;
    num dx = fx - x;
    num dy = fy - y;

    int _linear(int Icc, int Inc, int Icn, int Inn) {
      return (Icc +
              dx * (Inc - Icc + dy * (Icc + Inn - Icn - Inc)) +
              dy * (Icn - Icc))
          .toInt();
    }

    int Icc = getPixelSafe(x, y);
    int Inc = getPixelSafe(nx, y);
    int Icn = getPixelSafe(x, ny);
    int Inn = getPixelSafe(nx, ny);

    return getColor(
        _linear(getRed(Icc), getRed(Inc), getRed(Icn), getRed(Inn)),
        _linear(getGreen(Icc), getGreen(Inc), getGreen(Icn), getGreen(Inn)),
        _linear(getBlue(Icc), getBlue(Inc), getBlue(Icn), getBlue(Inn)),
        _linear(getAlpha(Icc), getAlpha(Inc), getAlpha(Icn), getAlpha(Inn)));
  }

  /// Get the pixel using cubic interpolation for non-integer pixel
  /// coordinates.
  int getPixelCubic(num fx, num fy) {
    int x = fx.toInt() - (fx >= 0.0 ? 0 : 1);
    int px = x - 1;
    int nx = x + 1;
    int ax = x + 2;
    int y = fy.toInt() - (fy >= 0.0 ? 0 : 1);
    int py = y - 1;
    int ny = y + 1;
    int ay = y + 2;

    var dx = fx - x;
    var dy = fy - y;

    num _cubic(num dx, num Ipp, num Icp, num Inp, num Iap) =>
        Icp + 0.5 * (dx * (-Ipp + Inp) +
                dx * dx * (2 * Ipp - 5 * Icp + 4 * Inp - Iap) +
                dx * dx * dx * (-Ipp + 3 * Icp - 3 * Inp + Iap));

    int Ipp = getPixelSafe(px, py);
    int Icp = getPixelSafe(x, py);
    int Inp = getPixelSafe(nx, py);
    int Iap = getPixelSafe(ax, py);
    num Ip0 = _cubic(dx, getRed(Ipp), getRed(Icp), getRed(Inp), getRed(Iap));
    num Ip1 =
        _cubic(dx, getGreen(Ipp), getGreen(Icp), getGreen(Inp), getGreen(Iap));
    num Ip2 =
        _cubic(dx, getBlue(Ipp), getBlue(Icp), getBlue(Inp), getBlue(Iap));
    num Ip3 =
        _cubic(dx, getAlpha(Ipp), getAlpha(Icp), getAlpha(Inp), getAlpha(Iap));

    int Ipc = getPixelSafe(px, y);
    int Icc = getPixelSafe(x, y);
    int Inc = getPixelSafe(nx, y);
    int Iac = getPixelSafe(ax, y);
    num Ic0 = _cubic(dx, getRed(Ipc), getRed(Icc), getRed(Inc), getRed(Iac));
    num Ic1 =
        _cubic(dx, getGreen(Ipc), getGreen(Icc), getGreen(Inc), getGreen(Iac));
    num Ic2 =
        _cubic(dx, getBlue(Ipc), getBlue(Icc), getBlue(Inc), getBlue(Iac));
    num Ic3 =
        _cubic(dx, getAlpha(Ipc), getAlpha(Icc), getAlpha(Inc), getAlpha(Iac));

    int Ipn = getPixelSafe(px, ny);
    int Icn = getPixelSafe(x, ny);
    int Inn = getPixelSafe(nx, ny);
    int Ian = getPixelSafe(ax, ny);
    num In0 = _cubic(dx, getRed(Ipn), getRed(Icn), getRed(Inn), getRed(Ian));
    num In1 =
        _cubic(dx, getGreen(Ipn), getGreen(Icn), getGreen(Inn), getGreen(Ian));
    num In2 =
        _cubic(dx, getBlue(Ipn), getBlue(Icn), getBlue(Inn), getBlue(Ian));
    num In3 =
        _cubic(dx, getAlpha(Ipn), getAlpha(Icn), getAlpha(Inn), getAlpha(Ian));

    int Ipa = getPixelSafe(px, ay);
    int Ica = getPixelSafe(x, ay);
    int Ina = getPixelSafe(nx, ay);
    int Iaa = getPixelSafe(ax, ay);
    num Ia0 = _cubic(dx, getRed(Ipa), getRed(Ica), getRed(Ina), getRed(Iaa));
    num Ia1 =
        _cubic(dx, getGreen(Ipa), getGreen(Ica), getGreen(Ina), getGreen(Iaa));
    num Ia2 =
        _cubic(dx, getBlue(Ipa), getBlue(Ica), getBlue(Ina), getBlue(Iaa));
    num Ia3 =
        _cubic(dx, getAlpha(Ipa), getAlpha(Ica), getAlpha(Ina), getAlpha(Iaa));

    num c0 = _cubic(dy, Ip0, Ic0, In0, Ia0);
    num c1 = _cubic(dy, Ip1, Ic1, In1, Ia1);
    num c2 = _cubic(dy, Ip2, Ic2, In2, Ia2);
    num c3 = _cubic(dy, Ip3, Ic3, In3, Ia3);

    return getColor(c0.toInt(), c1.toInt(), c2.toInt(), c3.toInt());
  }

  /// Set the pixel at the given [x], [y] coordinate to the [color].
  void setPixel(int x, int y, int color) {
    data[y * width + x] = color;
  }

  /// Set the pixel at the given [x], [y] coordinate to the [color].
  /// If the pixel coordinates are out of bounds, nothing is done.
  void setPixelSafe(int x, int y, int color) {
    if (boundsSafe(x, y)) {
      data[y * width + x] = color;
    }
  }

  /// Set the pixel at the given [x], [y] coordinate to the color
  /// [r], [g], [b], [a].
  ///
  /// This simply replaces the existing color, it does not do any alpha
  /// blending. Use [drawPixel] for that.
  void setPixelRgba(int x, int y, int r, int g, int b, [int a = 0xff]) {
    data[y * width + x] = getColor(r, g, b, a);
  }

  /// Return the average gray value of the image.
  int getWhiteBalance() {
    final len = data.length;
    int r = 0;
    int g = 0;
    int b = 0;
    for (int i = 0; i < len; ++i) {
      r += getRed(data[i]);
      g += getGreen(data[i]);
      b += getBlue(data[i]);
    }

    r ~/= len;
    g ~/= len;
    b ~/= len;

    return (r + g + b) ~/ 3;
  }

  static Uint32List _convertData(int width, int height, List<int> bytes,
                                 Format format) {
    if (format == Format.bgra) {
      return bytes is Uint32List
          ? Uint32List.fromList(bytes)
          : Uint32List.view(Uint8List.fromList(bytes).buffer);
    }

    List<int> input = bytes is Uint32List
        ? Uint8List.view(bytes.buffer)
        : bytes;

    Uint32List data = Uint32List(width * height);
    Uint8List bgra = Uint8List.view(data.buffer);

    switch (format) {
      case Format.bgra:
        for (int i = 0, len = input.length; i < len; ++i) {
          bgra[i] = input[i];
        }
        break;
      case Format.rgba:
        for (int i = 0, len = input.length; i < len; i += 4) {
          bgra[i + 0] = input[i + 2];
          bgra[i + 1] = input[i + 1];
          bgra[i + 2] = input[i + 0];
          bgra[i + 3] = input[i + 3];
        }
        break;
      case Format.abgr:
        for (int i = 0, len = input.length; i < len; i += 4) {
          bgra[i + 0] = input[i + 1];
          bgra[i + 1] = input[i + 2];
          bgra[i + 2] = input[i + 3];
          bgra[i + 3] = input[i + 0];
        }
        break;
      case Format.argb:
        for (int i = 0, len = input.length; i < len; i += 4) {
          bgra[i + 0] = input[i + 3];
          bgra[i + 1] = input[i + 2];
          bgra[i + 2] = input[i + 1];
          bgra[i + 3] = input[i + 0];
        }
        break;
      case Format.bgr:
        for (int i = 0, j = 0, len = input.length; i < len; i += 4, j += 3) {
          bgra[i + 0] = input[j + 0];
          bgra[i + 1] = input[j + 1];
          bgra[i + 2] = input[j + 2];
          bgra[i + 3] = 255;
        }
        break;
      case Format.rgb:
        for (int i = 0, j = 0, len = input.length; i < len; i += 4, j += 3) {
          bgra[i + 0] = input[j + 2];
          bgra[i + 1] = input[j + 1];
          bgra[i + 2] = input[j + 0];
          bgra[i + 3] = 255;
        }
        break;
      case Format.luminance:
        for (int i = 0, j = 0, len = input.length; i < len; i += 4, ++j) {
          bgra[i] = 255;
          bgra[i + 1] = input[j];
          bgra[i + 2] = input[j];
          bgra[i + 3] = input[j];
        }
        break;
    }

    return data;
  }
}
