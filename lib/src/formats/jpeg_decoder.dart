import 'dart:typed_data';

import '../image/image.dart';
import '../util/image_exception.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'image_format.dart';
import 'jpeg/jpeg_data.dart';
import 'jpeg/jpeg_info.dart';

/// Decode a jpeg encoded image.
class JpegDecoder extends Decoder {
  @Deprecated('Use Decoder.defaultMaxPixels')
  static int get defaultMaxPixels => Decoder.defaultMaxPixels;
  @Deprecated('Use Decoder.defaultMaxPixels')
  static set defaultMaxPixels(int value) => Decoder.defaultMaxPixels = value;

  /// The maximum number of pixels (width * height) this decoder will decode.
  /// Images declaring more throw an [ImageException] before any pixel data is
  /// allocated. A value <= 0 disables the limit.
  final int maxPixels;

  /// The factor the image is scaled down by while decoding: 1, 2, 4 or 8.
  /// Decoding at a reduced scale is much faster and uses less memory, so it's
  /// a good way to decode a thumbnail. The decoded image is the size of the
  /// JPEG divided by [scale], rounded up.
  final int scale;

  JpegInfo? info;
  InputBuffer? input;

  JpegDecoder({int? maxPixels, this.scale = 1})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels {
    if (scale != 1 && scale != 2 && scale != 4 && scale != 8) {
      throw ArgumentError.value(scale, 'scale', 'must be 1, 2, 4 or 8');
    }
  }

  @override
  ImageFormat get format => ImageFormat.jpg;

  /// Is the given file a valid JPEG image?
  @override
  bool isValidFile(Uint8List data) {
    if (data.length < 2 || data[0] != 0xff || data[1] != 0xd8) {
      return false;
    }
    try {
      return JpegData().validate(data);
    } catch (_) {
      return false;
    }
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    input = InputBuffer(bytes, bigEndian: true);
    return info = JpegData().readInfo(bytes);
  }

  @override
  int numFrames() => info == null ? 0 : info!.numFrames;

  @override
  Image? decodeFrame(int frame) {
    if (input == null) {
      return null;
    }
    return (JpegData()
          ..maxPixels = maxPixels
          ..scale = scale)
        .decodeImage(input!.buffer);
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) => (JpegData()
        ..maxPixels = maxPixels
        ..scale = scale)
      .decodeImage(bytes);
}
