import 'dart:typed_data';

import '../exif/exif_data.dart';
import '../image/image.dart';
import '../util/input_buffer.dart';
import '_guard_decode.dart';
import '_max_pixels.dart';
import 'decoder.dart';
import 'image_format.dart';
import 'tiff/tiff_image.dart';
import 'tiff/tiff_info.dart';

class TiffDecoder extends Decoder {
  TiffInfo? info;
  ExifData? exif;
  late InputBuffer _input;

  /// The maximum number of pixels (width * height) of an image, and of all
  /// the pages of a full decode. Larger images throw an ImageException.
  /// A value <= 0 disables the limit.
  final int maxPixels;

  TiffDecoder({int? maxPixels})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.tiff;

  /// Is the given file a valid TIFF image?
  @override
  bool isValidFile(Uint8List data) =>
      _readHeader(InputBuffer(data), firstImageOnly: true) != null;

  /// Validate the file is a TIFF image and get information about it.
  /// If the file is not a valid TIFF image, null is returned.
  @override
  TiffInfo? startDecode(Uint8List bytes) =>
      guardDecode(() => _startDecode(bytes));

  TiffInfo? _startDecode(Uint8List bytes) {
    _input = InputBuffer(bytes);
    info = _readHeader(_input);
    if (info != null) {
      exif = ExifData.fromInputBuffer(InputBuffer(bytes));
    }
    return info;
  }

  /// How many frames are available to be decoded. [startDecode] should have
  /// been called first. Non animated image files will have a single frame.
  @override
  int numFrames() => info != null ? info!.images.length : 0;

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0.
  @override
  Image? decodeFrame(int frame) => guardDecode(() => _decodeFrame(frame));

  Image? _decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    final tiff = info!.images[frame];
    checkPixels(tiff.width, tiff.height, maxPixels);
    checkPixels(tiff.tileWidth, tiff.tileHeight, maxPixels);
    final image = tiff.decode(_input);
    if (exif != null) {
      image.exif = exif!;
    }
    return image;
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  @override
  Image? decode(Uint8List bytes, {int? frame}) =>
      guardDecode(() => _decode(bytes, frame: frame));

  Image? _decode(Uint8List bytes, {int? frame}) {
    _input = InputBuffer(bytes);

    info = _readHeader(_input);
    if (info == null) {
      return null;
    }

    // By default decode all frames and include the metadata in the result.
    // Most tif images have only a single image.
    final len = numFrames();
    if (frame != null) {
      if (frame >= len) {
        throw RangeError.range(frame, 0, len - 1);
      }
      return decodeFrame(frame);
    }

    final budget = PixelBudget(maxPixels);
    for (final tiff in info!.images) {
      budget.add(tiff.width, tiff.height);
    }

    final image = decodeFrame(0);
    if (image == null) {
      return null;
    }
    image
      ..exif = ExifData.fromInputBuffer(InputBuffer(bytes))
      ..frameType = FrameType.page;

    for (var i = 1; i < len; ++i) {
      final frame = decodeFrame(i);
      image.addFrame(frame);
    }

    return image;
  }

  // Read the TIFF header and IFD blocks.
  TiffInfo? _readHeader(InputBuffer p, {bool firstImageOnly = false}) {
    final info = TiffInfo();
    if (p.length < 8) {
      return null;
    }
    final byteOrder = p.readUint16();
    if (byteOrder != tiffLittleEndian && byteOrder != tiffBigEndian) {
      return null;
    }

    if (byteOrder == tiffBigEndian) {
      p.bigEndian = true;
      info.bigEndian = true;
    } else {
      p.bigEndian = false;
      info.bigEndian = false;
    }

    info.signature = p.readUint16();
    if (info.signature != tiffSignature) {
      return null;
    }

    var offset = p.readUint32();
    info.ifdOffset = offset;

    final p2 = InputBuffer.from(p)..offset = offset;

    // Malformed data can make the chain of IFDs loop, so each IFD is read
    // once, and the number of them is limited.
    final visited = <int>{};
    while (offset != 0 &&
        offset < p.end &&
        info.images.length < _maxImages &&
        visited.add(offset)) {
      TiffImage img;
      try {
        img = TiffImage(p2);
        if (!img.isValid) {
          break;
        }
      } catch (error) {
        break;
      }
      info.images.add(img);
      if (info.images.length == 1) {
        info
          ..width = info.images[0].width
          ..height = info.images[0].height;
      }
      if (firstImageOnly) {
        break;
      }

      offset = p2.readUint32();
      if (offset != 0) {
        p2.offset = offset;
      }
    }

    return info.images.isNotEmpty ? info : null;
  }

  static const _maxImages = 1024;

  static const tiffSignature = 42;
  static const tiffLittleEndian = 0x4949;
  static const tiffBigEndian = 0x4d4d;
}
