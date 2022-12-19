import 'dart:typed_data';

import '../image/animation.dart';
import '../image/image.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'exr/exr_image.dart';

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

  ExrDecoder();

  @override
  bool isValidFile(Uint8List bytes) => ExrImage.isValidFile(bytes);

  @override
  DecodeInfo? startDecode(Uint8List bytes) => exrImage = ExrImage(bytes);

  @override
  int numFrames() => exrImage != null ? exrImage!.parts.length : 0;

  @override
  Image? decodeFrame(int frame) {
    if (exrImage == null) {
      return null;
    }

    return exrImage!.getPart(frame).framebuffer;
  }

  @override
  Image? decodeImage(Uint8List bytes, {int frame = 0}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  @override
  Animation? decodeAnimation(Uint8List bytes) {
    final image = decodeImage(bytes);
    if (image == null) {
      return null;
    }

    final anim = Animation()
    ..width = image.width
    ..height = image.height
    ..addFrame(image);

    return anim;
  }
}
