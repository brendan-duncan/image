part of image;

/**
 * Decode an OpenEXR formatted image.
 *
 * OpenEXR is a format developed by Industrial Light & Magic, with collaboration
 * from other companies such as Weta and Pixar, for storing hight dynamic
 * range (HDR) images for use in digital visual effects production. It supports
 * a wide range of features, including 16-bit or 32-bit floating-point channels;
 * lossless and lossy data compression; arbitrary image channels for storing
 * any combination of data, such as red, green, blue, alpha, luminance and
 * chroma channels, depth, surface normal, motion vectors, etc. It can also
 * store images in scanline or tiled format; multiple views for stereo images;
 * multiple parts; etc.
 *
 * Because OpenEXR is a high-dynamic-range (HDR) format, it must be converted
 * to a low-dynamic-range (LDR) image for display, or for use as an OpenGL
 * texture (for example). This process is called tone-mapping. Currently only
 * a simple tone-mapping function is provided with a single [exposure]
 * parameter. More tone-mapping functionality will be added.
 */
class ExrDecoder extends Decoder {
  ExrImage exrImage;
  /// Exposure for tone-mapping the hdr image to an [Image], applied during
  /// [decodeFrame].
  double exposure;
  double gamma;
  bool reinhard;
  double bloomAmount;
  double bloomRadius;

  ExrDecoder({this.exposure: 1.0});

  bool isValidFile(List<int> data) {
    return ExrImage.isValidFile(data);
  }

  DecodeInfo startDecode(List<int> data) {
    exrImage = new ExrImage(data);
    return exrImage;
  }

  int numFrames() => exrImage != null ? 1 : 0;

  Image decodeFrame(int frame) {
    if (exrImage == null) {
      return null;
    }

    return hdrToImage(exrImage.getPart(0).framebuffer, exposure: exposure);
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    if (startDecode(data) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
