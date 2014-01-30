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
      case WebPData.FORMAT_ANIMATED:
        return webp;
      case WebPData.FORMAT_LOSSLESS:
        input.position = webp._vp8Position;
        VP8L vp8l = new VP8L(input, webp);
        if (!vp8l.decodeHeader()) {
          return null;
        }
        return webp;
      case WebPData.FORMAT_LOSSY:
        input.position = webp._vp8Position;
        VP8 vp8 = new VP8(input, webp);
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
        int dp = webp._animPositions[i];
        int ds = webp._animSizes[i];
        Arc.InputStream data = input.subset(dp, ds);
        return new WebPFrame(data, webp).decode();
      }
    } else {
      Arc.InputStream data = input.subset(webp._vp8Position, webp._vp8Size);
      if (webp.format == WebPData.FORMAT_LOSSLESS) {
        return new VP8L(data, webp).decode();
      } else if (webp.format == WebPData.FORMAT_LOSSY) {
        return new VP8(data, webp).decode();
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
      if (data.format == WebPData.FORMAT_LOSSLESS) {
        Image image = new VP8L(input, data).decode();
        anim.addFrame(image);
      } else if (data.format == WebPData.FORMAT_LOSSY) {
        Image image = new VP8(input, data).decode();
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
      //print('    $tag');
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
          webp.format = WebPData.FORMAT_LOSSY;
          found = true;
          break;
        case 'VP8L':
          webp._vp8Position = input.position;
          webp._vp8Size = size;
          webp.format = WebPData.FORMAT_LOSSLESS;
          found = true;
          break;
        case 'ALPH':
          webp._alphaData = new Arc.InputStream(input.buffer,
              byteOrder: input.byteOrder);
          webp._alphaData.position = input.position;
          webp._alphaSize = size;
          input.skip(diskSize);
          break;
        case 'ANIM':
          webp.format = WebPData.FORMAT_ANIMATED;
          if (!_getAnimInfo(input, webp)) {
            return false;
          }
          break;
        case 'ANMF':
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

  bool _getVp8xInfo(Arc.InputStream input, WebPData webp) {
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

    webp.width = w;
    webp.height = h;
    webp.hasAnimation = a != 0;
    webp.hasAlpha = alpha != 0;

    return true;
  }

  bool _getAnimInfo(Arc.InputStream input, WebPData data) {
    data.animBackgroundColor = input.readUint32();
    data.animLoopCount = input.readUint16();
    return true;
  }
}
