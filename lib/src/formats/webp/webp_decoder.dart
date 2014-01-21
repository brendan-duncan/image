part of image;

class WebPDecoder {
  /**
   * Validate the file is a WebP image and get information about it.
   * If the file is not a valid WebP image, null is returned.
   */
  WebPData getInfo(List<int> bytes) {
    // WebP is stored in little-endian byte order.
    Arc.InputStream input = new Arc.InputStream(bytes);

    WebPData webp = new WebPData();
    if (!_getInfo(input, webp)) {
      return null;
    }

    switch (webp.format) {
      case WebP.FORMAT_LOSSLESS:
        input.position = webp._vp8Position;
        Vp8l vp8l = new Vp8l(input, webp);
        if (!vp8l.decodeHeader()) {
          return null;
        }
        return webp;
      case WebP.FORMAT_LOSSY:
        input.position = webp._vp8Position;
        Vp8 vp8 = new Vp8(input, webp);
        if (!vp8.decodeHeader()) {
          return null;
        }
        return webp;
    }

    return null;
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

    WebPData webp = new WebPData();
    if (!_getInfo(input, webp)) {
      return null;
    }

    if (webp.format == 0) {
      return null;
    }

    if (webp._animPositions.isNotEmpty) {
      for (int i = 0, len = webp._animPositions.length; i < len; ++i) {
        input.position = webp._animPositions[i];
        return new WebPFrame(input, webp).decode();
      }
    } else {
      input.position = webp._vp8Position;
      if (webp.format == WebP.FORMAT_LOSSLESS) {
        return new Vp8l(input, webp).decode();
      } else if (webp.format == WebP.FORMAT_LOSSY) {
        return new Vp8(input, webp).decode();
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
        Image image = new WebPFrame(input, data).decode();
        anim.addFrame(image);
      }
    } else {
      input.position = data._vp8Position;
      if (data.format == WebP.FORMAT_LOSSLESS) {
        Image image = new Vp8l(input, data).decode();
        anim.addFrame(image);
      } else if (data.format == WebP.FORMAT_LOSSY) {
        Image image = new Vp8(input, data).decode();
        anim.addFrame(image);
      }
    }

    return anim;
  }

  bool _getInfo(Arc.InputStream input, WebPData webp) {
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
          if (!_getVp8xInfo(input, webp)) {
            return false;
          }
          break;
        case 'VP8 ':
          webp._vp8Position = input.position;
          webp._vp8Size = size;
          webp.format = WebP.FORMAT_LOSSY;
          found = true;
          break;
        case 'VP8L':
          webp._vp8Position = input.position;
          webp._vp8Size = size;
          webp.format = WebP.FORMAT_LOSSLESS;
          found = true;
          break;
        case 'ALPH':
          webp._alphaPosition = input.position;
          webp._alphaSize = size;
          input.skip(diskSize);
          break;
        case 'ANIM':
          if (!_getAnimInfo(input, webp)) {
            return false;
          }
          break;
        case 'ANIMF':
          webp._animPositions.add(input.position);
          webp._animSizes.add(size);
          input.skip(diskSize);
          break;
        case 'ICCP':
          webp.iccp = input.readString(size);
          break;
        case 'EXIF':
          webp.exif = input.readString(size);
          break;
        case 'XMP ':
          webp.xmp = input.readString(size);
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

    return webp.format != 0;
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
}
