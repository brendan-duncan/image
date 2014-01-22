part of image;

/**
 * WebP lossy format.
 */
class Vp8 {
  Arc.InputStream input;
  WebPData webp;

  Vp8(Arc.InputStream input, this.webp) :
    this.input = input;

  bool decodeHeader() {
    int bits = input.readUint24();
    final bool keyFrame = (bits & 1) == 0;
    if (!keyFrame) {
      return false;
    }

    if (((bits >> 1) & 7) > 3) {
      return false; // unknown profile
    }

    if (((bits >> 4) & 1) == 0) {
      return false; // first frame is invisible!
    }

    int signature = input.readUint24();
    if (signature != VP8_SIGNATURE) {
      return false;
    }

    webp.width = input.readUint16();
    webp.height = input.readUint16();
    return true;
  }

  Image decode() {
    if (!decodeHeader()) {
      return null;
    }
    Image image = new Image(webp.width, webp.height);
    return image;
  }

  static const int VP8_SIGNATURE = 0x2a019d;
}
