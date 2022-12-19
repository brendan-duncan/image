import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint8.dart';
import '../color/color_util.dart';
import '../color/format.dart';
import '../exif/exif_data.dart';
import '../util/image_exception.dart';
import '../util/interpolation.dart';
import 'frame_info.dart';
import 'icc_profile.dart';
import 'image_data.dart';
import 'image_data_float16.dart';
import 'image_data_float32.dart';
import 'image_data_float64.dart';
import 'image_data_int16.dart';
import 'image_data_int32.dart';
import 'image_data_int8.dart';
import 'image_data_uint1.dart';
import 'image_data_uint16.dart';
import 'image_data_uint2.dart';
import 'image_data_uint32.dart';
import 'image_data_uint4.dart';
import 'image_data_uint8.dart';
import 'palette.dart';
import 'palette_float16.dart';
import 'palette_float32.dart';
import 'palette_float64.dart';
import 'palette_int16.dart';
import 'palette_int32.dart';
import 'palette_int8.dart';
import 'palette_uint16.dart';
import 'palette_uint32.dart';
import 'palette_uint8.dart';
import 'pixel.dart';

class Image extends Iterable<Pixel> {
  ImageData? data;
  Map<String, ImageData>? extra;
  FrameInfo? _frameInfo;
  IccProfile? iccProfile;
  Map<String, String>? textData;
  ExifData? _exif;

  /// Creates an image with the given dimensions and format.
  Image(int width, int height,
      { Format format = Format.uint8, int numChannels = 3,
        bool isFrame = false,
        bool withPalette = false,
        Format paletteFormat = Format.uint8,
        Palette? palette, ExifData? exif,
        IccProfile? iccp, this.textData }) {
    _initialize(width, height, format: format, numChannels: numChannels,
        isFrame: isFrame, withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif,
        iccp: iccp);
  }

  /// Creates a copy of the given Image [other].
  Image.from(Image other)
      : data = other.data?.clone()
      , _frameInfo = other._frameInfo?.clone()
      , _exif = other._exif?.clone()
      , iccProfile = other.iccProfile?.clone() {
    if (other.extra != null) {
      extra = Map<String, ImageData>.from(other.extra!);
    }
    if (other.textData != null) {
      textData = Map<String, String>.from(other.textData!);
    }
  }

  /// Creates an empty image.
  Image.empty();

  /// Create an image from raw data in [bytes].
  ///
  /// [format] defines the order of color channels in [bytes].
  /// An HTML canvas element stores colors in Format.rgba format; a Flutter
  /// Image object stores colors in Format.rgba format.
  /// The length of [bytes] should be (width * height) * format-byte-count,
  /// where format-byte-count is 1, 3, or 4 depending on the number of
  /// channels in the format (luminance, rgb, rgba, etc).
  ///
  /// The native format of an image is Format.rgba. If another format
  /// is specified, the input data will be converted to rgba to store
  /// in the Image.
  ///
  /// For example, given an Html Canvas, you could create an image:
  /// var bytes = canvas.getContext('2d').getImageData(0, 0,
  ///   canvas.width, canvas.height).data;
  /// var image = Image.fromBytes(canvas.width, canvas.height, bytes,
  ///                             numChannels: 4);
  Image.fromBytes(int width, int height, ByteBuffer bytes,
      { Format format = Format.uint8, int numChannels = 3,
        int? rowStride,
        bool isFrame = false,
        bool withPalette = false,
        Format paletteFormat = Format.uint8,
        Palette? palette, ExifData? exif,
        IccProfile? iccp, this.textData }) {
    _initialize(width, height, format: format, numChannels: numChannels,
        isFrame: isFrame, withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif,
        iccp: iccp);

    if (data == null) {
      return;
    }

    final dataView = data!.toUint8List();
    final byteView = Uint8List.view(bytes);

    rowStride ??= width * numChannels * formatSize[format]!;
    final dataStride = data!.rowStride;
    final stride = min(rowStride, dataStride);

    var dOff = 0;
    var bOff = 0;
    for (int y = 0; y < height; ++y, bOff += rowStride, dOff += dataStride) {
      final bRow = byteView.getRange(bOff, bOff + stride);
      dataView.setRange(dOff, dOff + dataStride, bRow);
    }
  }

  void _initialize(int width, int height,
      { Format format = Format.uint8, int numChannels = 3,
        bool isFrame = false,
        bool withPalette = false,
        Format paletteFormat = Format.uint8,
        Palette? palette, ExifData? exif,
        IccProfile? iccp }) {
    if (numChannels < 1 || numChannels > 4) {
      throw ImageException('Invalid number of channels for image $numChannels.'
          ' Must be between 1 and 4.');
    }
    this.iccProfile = iccp;
    if (exif != null) {
      _exif = ExifData.from(exif);
    }
    if (isFrame) {
      _frameInfo = FrameInfo();
    }
    if (palette == null && withPalette && supportsPalette) {
      palette = _createPalette(paletteFormat, numChannels);
    }

    switch (format) {
      case Format.uint1:
        if (palette == null) {
          data = ImageDataUint1(width, height, numChannels);
        } else {
          data = ImageDataUint1.palette(width, height, palette);
        }
        break;
      case Format.uint2:
        if (palette == null) {
          data = ImageDataUint2(width, height, numChannels);
        } else {
          data = ImageDataUint2.palette(width, height, palette);
        }
        break;
      case Format.uint4:
        if (palette == null) {
          data = ImageDataUint4(width, height, numChannels);
        } else {
          data = ImageDataUint4.palette(width, height, palette);
        }
        break;
      case Format.uint8:
        if (palette == null) {
          data = ImageDataUint8(width, height, numChannels);
        } else {
          data = ImageDataUint8.palette(width, height, palette);
        }
        break;
      case Format.uint16:
        data = ImageDataUint16(width, height, numChannels);
        break;
      case Format.uint32:
        data = ImageDataUint32(width, height, numChannels);
        break;
      case Format.int8:
        data = ImageDataInt8(width, height, numChannels);
        break;
      case Format.int16:
        data = ImageDataInt16(width, height, numChannels);
        break;
      case Format.int32:
        data = ImageDataInt32(width, height, numChannels);
        break;
      case Format.float16:
        data = ImageDataFloat16(width, height, numChannels);
        break;
      case Format.float32:
        data = ImageDataFloat32(width, height, numChannels);
        break;
      case Format.float64:
        data = ImageDataFloat64(width, height, numChannels);
        break;
    }
  }

  /// Create a copy of this image.
  Image clone() => Image.from(this);

  /// String representation of the image.
  String toString() => 'Image($width, $height, ${format.name}, $numChannels)';

  /// The width of the image in pixels.
  int get width => data?.width ?? 0;

  /// The height of the image in pixels.
  int get height => data?.height ?? 0;

  /// The format of the image pixels.
  Format get format => data?.format ?? Format.uint8;

  /// The general type of the format, whether it's Uint data, Int data, or
  /// Float data (regardless of precision).
  FormatType get formatType => data?.formatType ?? FormatType.uint;

  /// If the image has animation frame info.
  bool get hasFrameInfo => _frameInfo != null;

  /// The animation frame metadata for the image.
  FrameInfo get frameInfo {
    if (_frameInfo == null) {
      _frameInfo = FrameInfo();
    }
    return _frameInfo!;
  }

  void set frameInfo(FrameInfo f) => _frameInfo = f;

  /// The exif metadata for the image. If an ExifData hasn't been created
  /// for the image yet, one will be added.
  ExifData get exif {
    if (_exif == null) {
      _exif = ExifData();
    }
    return _exif!;
  }

  set exif(ExifData exif) => _exif = exif;

  bool hasExtraChannel(String name) =>
      extra != null && extra!.containsKey(name);

  ImageData? getExtraChannel(String name) =>
      extra != null ? extra![name] : null;

  void setExtraChannel(String name, ImageData? data) {
    if (extra == null && data == null) {
      return;
    }

    if (extra == null) {
      extra = {};
    }

    if (data == null) {
      extra!.remove(name);
    } else {
      extra![name] = data;
    }

    if (extra!.isEmpty) {
      extra = null;
    }
  }

  /// Returns a pixel iterator for iterating over all of the pixels in the
  /// image.
  Iterator<Pixel> get iterator => data!.iterator;

  /// returns a pixel iterator for iterating over a rectangular range of pixels
  /// in the image.
  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
    data!.getRange(x, y, width, height);

  /// Is true if the image is valid and has data.
  bool get isValid => data != null && width > 0 && height > 0;

  /// The [ByteBuffer] of the image storage data.
  ByteBuffer get buffer => data?.buffer ?? Uint8List(0).buffer;

  /// Get a Uint8List view of the image storage data.
  Uint8List toUint8List() => data?.toUint8List() ?? Uint8List(0);

  /// The length in bytes of the image data buffer.
  int get lengthInBytes => data?.buffer.lengthInBytes ?? 0;

  /// The length in bytes of a row of pixels in the image buffer.
  int get rowStride => data?.rowStride ?? 0;

  /// The number of color channels for the image.
  int get numChannels => palette?.numChannels ?? data?.numChannels ?? 0;

  /// Is true if the image format is a low dynamic range (regular) image.
  bool get isLdrFormat => data?.isLdrFormat ?? false;

  /// Is true if the image is a high dynamic range image.
  bool get isHdrFormat => data?.isHdrFormat ?? false;

  /// Is true if the image has a palette.
  bool get hasPalette => data?.palette != null;

  /// The palette if the image has one, null otherwise.
  Palette? get palette => data?.palette;

  /// The number of bits per color channel.
  int get bitsPerChannel => data?.bitsPerChannel ?? 0;

  /// Returns true if the given pixel coordinates is within the dimensions
  /// of the image.
  bool isBoundsSafe(int x, int y) => x >= 0 && y >= 0 &&
      x < width && y < height;

  /// Create a [Color] object with the format and number of channels of the
  /// image.
  Color getColor(num r, num g, num b, [num? a]) =>
      data?.getColor(r, g, b, a) ?? ColorUint8(0);

  /// Return the [Pixel] at the given coordinates. If [pixel] is provided,
  /// it will be updated and returned rather than allocating a new [Pixel].
  Pixel getPixel(int x, int y, [Pixel? pixel]) =>
      data?.getPixel(x, y, pixel) ?? Pixel.undefined;

  /// Get the pixel from the given [x], [y] coordinate. If the pixel coordinates
  /// are out of bounds, PixelUndefined is returned.
  Pixel getPixelSafe(int x, int y, [Pixel? pixel]) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return Pixel.undefined;
    }
    return data?.getPixel(x, y, pixel) ?? Pixel.undefined;
  }

  /// Get the pixel using the given [interpolation] type for non-integer pixel
  /// coordinates.
  Color getPixelInterpolate(num fx, num fy,
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
  Color getPixelLinear(num fx, num fy) {
    final x = fx.toInt() - (fx >= 0 ? 0 : 1);
    final nx = x + 1;
    final y = fy.toInt() - (fy >= 0 ? 0 : 1);
    final ny = y + 1;
    final dx = fx - x;
    final dy = fy - y;

    num _linear(num Icc, num Inc, num Icn, num Inn) =>
        Icc + dx * (Inc - Icc + dy * (Icc + Inn - Icn - Inc)) +
            dy * (Icn - Icc);

    final Icc = getPixelSafe(x, y);
    final Icn = ny >= height ? Icc : getPixelSafe(x, ny);
    final Inc = nx >= width ? Icc : getPixelSafe(nx, y);
    final Inn = nx >= width || ny >= height ? Icc : getPixelSafe(nx, ny);

    return getColor(
        _linear(Icc.r, Inc.r, Icn.r, Inn.r),
        _linear(Icc.g, Inc.g, Icn.g, Inn.g),
        _linear(Icc.b, Inc.b, Icn.b, Inn.b),
        _linear(Icc.a, Inc.a, Icn.a, Inn.a));
  }

  /// Get the pixel using cubic interpolation for non-integer pixel
  /// coordinates.
  Color getPixelCubic(num fx, num fy) {
    final x = fx.toInt() - (fx >= 0.0 ? 0 : 1);
    final px = x - 1;
    final nx = x + 1;
    final ax = x + 2;
    final y = fy.toInt() - (fy >= 0.0 ? 0 : 1);
    final py = y - 1;
    final ny = y + 1;
    final ay = y + 2;

    final dx = fx - x;
    final dy = fy - y;

    num _cubic(num dx, num Ipp, num Icp, num Inp, num Iap) =>
        Icp +
            0.5 *
                (dx * (-Ipp + Inp) +
                    dx * dx * (2 * Ipp - 5 * Icp + 4 * Inp - Iap) +
                    dx * dx * dx * (-Ipp + 3 * Icp - 3 * Inp + Iap));

    final Icc = getPixelSafe(x, y);

    final Ipp = px < 0 || py < 0 ? Icc : getPixelSafe(px, py);
    final Icp = px < 0 ? Icc : getPixelSafe(x, py);
    final Inp = py < 0 || nx >= width ? Icc : getPixelSafe(nx, py);
    final Iap = ax >= width || py < 0 ? Icc : getPixelSafe(ax, py);

    final Ip0 = _cubic(dx, Ipp.r, Icp.r, Inp.r, Iap.r);
    final Ip1 = _cubic(dx, Ipp.g, Icp.g, Inp.g, Iap.g);
    final Ip2 = _cubic(dx, Ipp.b, Icp.b, Inp.b, Iap.b);
    final Ip3 = _cubic(dx, Ipp.a, Icp.a, Inp.a, Iap.a);

    final Ipc = px < 0 ? Icc : getPixelSafe(px, y);
    final Inc = nx >= width ? Icc : getPixelSafe(nx, y);
    final Iac = ax >= width ? Icc : getPixelSafe(ax, y);

    final Ic0 = _cubic(dx, Ipc.r, Icc.r, Inc.r, Iac.r);
    final Ic1 = _cubic(dx, Ipc.g, Icc.g, Inc.g, Iac.g);
    final Ic2 = _cubic(dx, Ipc.b, Icc.b, Inc.b, Iac.b);
    final Ic3 = _cubic(dx, Ipc.a, Icc.a, Inc.a, Iac.a);

    final Ipn = px < 0 || ny >= height ? Icc : getPixelSafe(px, ny);
    final Icn = ny >= height ? Icc : getPixelSafe(x, ny);
    final Inn = nx >= width || ny >= height ? Icc : getPixelSafe(nx, ny);
    final Ian = ax >= width || ny >= height ? Icc : getPixelSafe(ax, ny);

    final In0 = _cubic(dx, Ipn.r, Icn.r, Inn.r, Ian.r);
    final In1 = _cubic(dx, Ipn.g, Icn.g, Inn.g, Ian.g);
    final In2 = _cubic(dx, Ipn.b, Icn.b, Inn.b, Ian.b);
    final In3 = _cubic(dx, Ipn.a, Icn.a, Inn.a, Ian.a);

    final Ipa = px < 0 || ay >= height ? Icc : getPixelSafe(px, ay);
    final Ica = ay >= height ? Icc : getPixelSafe(x, ay);
    final Ina = nx >= width || ay >= height ? Icc : getPixelSafe(nx, ay);
    final Iaa = ax >= width || ay >= height ? Icc : getPixelSafe(ax, ay);

    final Ia0 = _cubic(dx, Ipa.r, Ica.r, Ina.r, Iaa.r);
    final Ia1 = _cubic(dx, Ipa.g, Ica.g, Ina.g, Iaa.g);
    final Ia2 = _cubic(dx, Ipa.b, Ica.b, Ina.b, Iaa.b);
    final Ia3 = _cubic(dx, Ipa.a, Ica.a, Ina.a, Iaa.a);

    final c0 = _cubic(dy, Ip0, Ic0, In0, Ia0);
    final c1 = _cubic(dy, Ip1, Ic1, In1, Ia1);
    final c2 = _cubic(dy, Ip2, Ic2, In2, Ia2);
    final c3 = _cubic(dy, Ip3, Ic3, In3, Ia3);

    return getColor(c0.toInt(), c1.toInt(), c2.toInt(), c3.toInt());
  }

  /// Set the color of the pixel at the given coordinates to the color of the
  /// given Color [c].
  void setPixel(int x, int y, Color c) {
    if (c is Pixel) {
      if (c.image.hasPalette) {
        if (hasPalette) {
          data?.setPixelColor(x, y, c.index);
          return;
        }
      }
    }
    data?.setPixelColor(x, y, c.r, c.g, c.b, c.a);
  }

  /// Set the color of the [Pixel] at the given coordinates to the given
  /// color values [r], [g], [b], and [a].
  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 0]) =>
      data?.setPixelColor(x, y, r, g, b, a);

  /// The maximum value of a pixel color channel. In the case of the float
  /// image formats, the maxChannelValue will be 1.0, even though channel values
  /// can exceed that.
  num get maxChannelValue => data?.maxChannelValue ?? 0;

  /// Is true if this image format supports using a palette.
  bool get supportsPalette => format == Format.uint1 ||
      format == Format.uint2 ||
      format == Format.uint4 ||
      format == Format.uint8;

  /// Set all pixels in the image to the given [color]. If no color is provided
  /// the image will be initialized to 0.
  void clear([Color? color]) => data?.clear(color);

  /// Convert this image to a new [format] or number of channels.
  Image convert({Format? format, int? numChannels, num? alpha}) {
    if (format == null || format == this.format) {
      if (numChannels == null || numChannels == this.numChannels) {
        // Same format and number of channels
        return Image.from(this);
      }
      // Same format, different number of channels
    }

    format ??= this.format;
    numChannels ??= this.numChannels;

    final newImage = Image(width, height, format: format,
        numChannels: numChannels,
        exif: _exif?.clone(), iccp: iccProfile?.clone());

    newImage.textData = textData != null ?
        Map<String, String>.from(textData!) : null;

    newImage._frameInfo = _frameInfo?.clone();

    Pixel? p2;
    for (var p in newImage) {
      p2 = getPixel(p.x, p.y, p2);
      final c = convertColor(p2, format: format, numChannels: numChannels,
          alpha: alpha);
      p.set(c);
    }

    return newImage;
  }

  /// Add text metadata to the image.
  void addTextData(Map<String, String> data) {
    if (textData == null) {
      textData = {};
    }
    for (var key in data.keys) {
      textData![key] = data[key]!;
    }
  }

  int get _numPixelColors =>
      format == Format.uint1 ? 2 :
      format == Format.uint2 ? 4 :
      format == Format.uint4 ? 16 :
      format == Format.uint8 ? 256 :
      0;

  Palette? _createPalette(Format paletteFormat, int numChannels) {
    switch (paletteFormat) {
      case Format.uint1:
        return null;
      case Format.uint2:
        return null;
      case Format.uint4:
        return null;
      case Format.uint8:
        return PaletteUint8(_numPixelColors, numChannels);
      case Format.uint16:
        return PaletteUint16(_numPixelColors, numChannels);
      case Format.uint32:
        return PaletteUint32(_numPixelColors, numChannels);
      case Format.int8:
        return PaletteInt8(_numPixelColors, numChannels);
      case Format.int16:
        return PaletteInt16(_numPixelColors, numChannels);
      case Format.int32:
        return PaletteInt32(_numPixelColors, numChannels);
      case Format.float16:
        return PaletteFloat16(_numPixelColors, numChannels);
      case Format.float32:
        return PaletteFloat32(_numPixelColors, numChannels);
      case Format.float64:
        return PaletteFloat64(_numPixelColors, numChannels);
    }
  }
}
