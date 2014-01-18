part of image;

class WebPDecoder {
  WebPFeatures getInfo(List<int> bytes) {
    Arc.InputBuffer input = new Arc.InputBuffer(bytes);

    WebPFeatures features = new WebPFeatures();

    if (!_getInfo(input, features)) {
      return null;
    }

    return features;
  }

  bool _getInfo(Arc.InputBuffer input, WebPFeatures features) {
    // Validate the webp format header
    String tag = input.readString(4);
    if (tag != 'RIFF') {
      return false;
    }

    int fileSize = input.readUint32();

    tag = input.readString(4);
    if (tag != 'WEBP') {
      return false;
    }

    bool found = false;
    while (!input.isEOF && !found) {
      tag = input.readString(4);
      int size = input.readUint32();
      // For odd sized chunks, there's a 1 byte padding at the end.
      int diskSize = ((size + 1) >> 1) << 1;
      int p = input.position;

      switch (tag) {
        case 'VP8X':
          if (!_getVp8xInfo(input, features)) {
            return false;
          }
          break;
        case 'VP8 ':
          if (!_getVp8Info(input, features)) {
            return false;
          }
          found = true;
          break;
        case 'VP8L':
          if (!_getVp8lInfo(input, features)) {
            return false;
          }
          found = true;
          break;
        default:
          input.skip(diskSize);
          break;
      }

      int remainder = diskSize - (input.position - p);
      input.skip(remainder);
    }

    return features.format != 0;
  }

  bool _getVp8xInfo(Arc.InputBuffer input, WebPFeatures features) {
    if (input.readBits(2) != 0) {
      return false;
    }
    int icc = input.readBits(1);
    int alpha = input.readBits(1);
    int exif = input.readBits(1);
    int xmp = input.readBits(1);
    int a = input.readBits(1);
    if (input.readBits(1) != 0) {
      return false;
    }
    if (input.readUint24() != 0) {
      return false;
    }
    int w = input.readUint24() + 1;
    int h = input.readUint24() + 1;

    features.width = w;
    features.height = h;
    features.hasAnimation = a != 0;
    features.hasAlpha = alpha != 0;

    return true;
  }

  bool _getVp8Info(Arc.InputBuffer input, WebPFeatures features) {
    features.format = 1;
    // Check the signature
    //int signature = input.readUint24();
    return true;
  }

  bool _getVp8lInfo(Arc.InputBuffer input, WebPFeatures features) {
    int signature = input.readByte();
    if (signature != WebP.VP8L_MAGIC_BYTE) {
      return false;
    }

    int w = input.readUint32();

    features.format = 2;
    features.width = (w & 0x3FFF) + 1;
    features.height = ((w >> 14) & 0x3FFF) + 1;
    features.hasAlpha = ((w >> 28) & 0x1) != 0;
    int version = ((w >> 29) & 0x3);
    if (version != 0) {
      return false;
    }

    return true;
  }
}
