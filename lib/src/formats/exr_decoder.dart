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
///
/// Because OpenEXR is a high-dynamic-range (HDR) format, it must be converted
/// to a low-dynamic-range (LDR) image for display, or for use as an OpenGL
/// texture (for example). This process is called tone-mapping. Currently only
/// a simple tone-mapping function is provided with a single [exposure]
/// parameter. More tone-mapping functionality will be added.
class ExrDecoder extends Decoder {
  ExrImage? exrImage;

  /// Exposure for tone-mapping the hdr image to an [Image], applied during
  /// [decodeFrame].
  double exposure;
  double? gamma;
  bool? reinhard;
  double? bloomAmount;
  double? bloomRadius;

  ExrDecoder({this.exposure = 1.0});

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

    final anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
