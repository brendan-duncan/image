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
  /// The [maxPixels] used by decoders created without one, including the
  /// decoders used by decodeImage and decodeJpg. The default of 2^28
  /// (16384 x 16384) allows very large photos while preventing a small,
  /// malicious file from declaring dimensions that would exhaust memory.
  /// A value <= 0 disables the limit.
  static int defaultMaxPixels = 1 << 28;

  /// The maximum number of pixels (width * height) this decoder will decode.
  /// Images declaring more throw an [ImageException] before any pixel data is
  /// allocated. A value <= 0 disables the limit.
  final int maxPixels;

  JpegInfo? info;
  InputBuffer? input;

  JpegDecoder({int? maxPixels}) : maxPixels = maxPixels ?? defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.jpg;

  /// Is the given file a valid JPEG image?
  @override
  bool isValidFile(Uint8List data) {
    if (data.length < 2 || data[0] != 0xff || data[1] != 0xd8) {
      return false;
    }
    return JpegData().validate(data);
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
    final jpeg = JpegData()
      ..maxPixels = maxPixels
      ..read(input!.buffer);
    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    final jpeg = JpegData()
      ..maxPixels = maxPixels
      ..read(bytes);

    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
  }
}
