part of image;

class WebPDecoder {
  /**
   * Validate the file is a WebP image and get information about it.
   * If the file is not a valid WebP image, null is returned.
   */
  WebPData getInfo(List<int> bytes) {
    // WebP is stored in little-endian byte order.
    Arc.InputStream input = new Arc.InputStream(bytes);

    WebPData data = new WebPData();
    if (!_getInfo(input, data)) {
      return null;
    }

    return data;
  }

  /**
   * Decode a WebP formatted file stored in [bytes] into an Image.
   * If it's not a valid webp file, null is returned.
   * If the webp file stores animated frames, only the first image will
   * be returned.  Use [decodeAnimation] to decode the full animation.
   */
  Image decodeImage(List<int> bytes) {
    // WebP is stored in little-endian byte order.
    Arc.InputStream input = new Arc.InputStream(bytes);

    WebPData data = new WebPData();
    if (!_getInfo(input, data)) {
      return null;
    }

    if (data._animPositions.isNotEmpty) {
      for (int i = 0, len = data._animPositions.length; i < len; ++i) {
        input.position = data._animPositions[i];
        return new WebPFrame().decode(input, data);
      }
    } else {
      input.position = data._vp8Position;
      if (data.format == WebP.FORMAT_LOSSLESS) {
        return new Vp8l(input, data).decode();
      } else if (data.format == WebP.FORMAT_LOSSY) {
        return new Vp8().decode(input, data);
      }
    }

    return null;
  }

  Animation decodeAnimation(List<int> bytes) {
    // WebP is stored in little-endian byte order.
    Arc.InputStream input = new Arc.InputStream(bytes);

    WebPData data = new WebPData();
    if (!_getInfo(input, data)) {
      return null;
    }

    Animation anim = new Animation();
    anim.loopCount = data.animLoopCount;

    if (data._animPositions.isNotEmpty) {
      for (int i = 0, len = data._animPositions.length; i < len; ++i) {
        input.position = data._animPositions[i];
        Image image = new WebPFrame().decode(input, data);
        anim.addFrame(image);
      }
    } else {
      input.position = data._vp8Position;
      if (data.format == WebP.FORMAT_LOSSLESS) {
        Image image = new Vp8l(input, data).decode();
        anim.addFrame(image);
      } else if (data.format == WebP.FORMAT_LOSSY) {
        Image image = new Vp8().decode(input, data);
        anim.addFrame(image);
      }
    }

    return anim;
  }

  bool _getInfo(Arc.InputStream input, WebPData data) {
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
    while (!input.isEOS && !found) {
      tag = input.readString(4);
      int size = input.readUint32();
      // For odd sized chunks, there's a 1 byte padding at the end.
      int diskSize = ((size + 1) >> 1) << 1;
      int p = input.position;

      switch (tag) {
        case 'VP8X':
          if (!_getVp8xInfo(input, data)) {
            return false;
          }
          break;
        case 'VP8 ':
          data._vp8Position = input.position;
          data._vp8Size = size;
          if (!_getVp8Info(input, data)) {
            return false;
          }
          found = true;
          break;
        case 'VP8L':
          data._vp8Position = input.position;
          data._vp8Size = size;
          if (!_getVp8lInfo(input, data)) {
            return false;
          }
          found = true;
          break;
        case 'ALPH':
          data._alphaPosition = input.position;
          data._alphaSize = size;
          input.skip(diskSize);
          break;
        case 'ANIM':
          if (!_getAnimInfo(input, data)) {
            return false;
          }
          break;
        case 'ANIMF':
          data._animPositions.add(input.position);
          data._animSizes.add(size);
          input.skip(diskSize);
          break;
        case 'ICCP':
          data.iccp = input.readString(size);
          break;
        case 'EXIF':
          data.exif = input.readString(size);
          break;
        case 'XMP ':
          data.xmp = input.readString(size);
          break;
        default:
          print('UNKNOWN WEBP TAG: $tag');
          input.skip(diskSize);
          break;
      }

      int remainder = diskSize - (input.position - p);
      if (remainder > 0) {
        input.skip(remainder);
      }
    }

    return data.format != 0;
  }

  bool _getVp8xInfo(Arc.InputStream input, WebPData data) {
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

    data.width = w;
    data.height = h;
    data.hasAnimation = a != 0;
    data.hasAlpha = alpha != 0;

    return true;
  }

  bool _getAnimInfo(Arc.InputStream input, WebPData data) {
    data.animBackgroundColor = input.readUint32();
    data.animLoopCount = input.readUint16();
    return true;
  }

  bool _getVp8Info(Arc.InputStream input, WebPData data) {
    data.format = WebP.FORMAT_LOSSY;
    // Check the signature
    //int signature = input.readUint24();
    return true;
  }

  bool _getVp8lInfo(Arc.InputStream input, WebPData data) {
    int signature = input.readByte();
    if (signature != WebP.VP8L_MAGIC_BYTE) {
      return false;
    }

    int w = input.readUint32();

    data.format = WebP.FORMAT_LOSSLESS;
    data.width = (w & 0x3FFF) + 1;
    data.height = ((w >> 14) & 0x3FFF) + 1;
    data.hasAlpha = ((w >> 28) & 0x1) != 0;
    int version = ((w >> 29) & 0x3);
    if (version != 0) {
      return false;
    }

    return true;
  }
}
