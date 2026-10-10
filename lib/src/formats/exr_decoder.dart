import 'dart:typed_data';

import '../image/image.dart';
import '_guard_decode.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'exr/exr_image.dart';
import 'image_format.dart';

/// Decode an OpenEXR formatted image.
///
/// OpenEXR is a format developed by Industrial Light & Magic, with
/// collaboration from other companies such as Weta and Pixar, for storing high
/// dynamic range (HDR) images for use in digital visual effects production.
/// It supports a wide range of features, including 16-bit or 32-bit
/// floating-point channels; lossless and lossy data compression; arbitrary
/// image channels for storing any combination of data, such as red, green,
/// blue, alpha, luminance and chroma channels, depth, surface normal,
/// motion vectors, etc. It can also store images in scanline or tiled format;
/// multiple views for stereo images; multiple parts; etc.
class ExrDecoder extends Decoder {
  ExrImage? exrImage;

  /// The maximum number of pixels (width * height) of the image, and of all
  /// of its parts. Larger images throw an ImageException. A value <= 0
  /// disables the limit.
  final int maxPixels;

  ExrDecoder({int? maxPixels})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.exr;

  @override
  bool isValidFile(Uint8List bytes) => ExrImage.isValidFile(bytes);

  @override
  DecodeInfo? startDecode(Uint8List bytes) =>
      guardDecode(() => _startDecode(bytes));

  DecodeInfo? _startDecode(Uint8List bytes) =>
      exrImage = ExrImage(bytes, maxPixels: maxPixels);

  @override
  int numFrames() => exrImage != null ? exrImage!.parts.length : 0;

  @override
  Image? decodeFrame(int frame) => guardDecode(() => _decodeFrame(frame));

  Image? _decodeFrame(int frame) {
    if (exrImage == null) {
      return null;
    }

    return exrImage!.getPart(frame).framebuffer;
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) =>
      guardDecode(() => _decode(bytes, frame: frame));

  Image? _decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame ?? 0);
  }
}
