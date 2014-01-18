part of image;

class WebPDecoder {
  WebPFeatures getInfo(List<int> bytes) {
    Arc.InputBuffer input = new Arc.InputBuffer(bytes);

    WebPFeatures features = new WebPFeatures();

    if (_getInfo(input, features) != WebP.VP8_STATUS_OK) {
      return null;
    }

    return features;
  }

  int _getInfo(Arc.InputBuffer input, WebPFeatures features) {
    // Validate the webp format header
    String tag = input.readString(4);
    if (tag != 'RIFF') {
      return WebP.VP8_STATUS_INVALID_PARAM;
    }

    int fileSize = input.readUint32();

    tag = input.readString(4);
    if (tag != 'WEBP') {
      return WebP.VP8_STATUS_INVALID_PARAM;
    }

    tag = input.readString(4);
    print(tag);
    if (tag == 'VP8 ') {
      print('LOSSY');
    } else if (tag == 'VP8L') {
      print('LOSSLESS');
    }

    return WebP.VP8_STATUS_OK;
  }

  bool _testForTag(Arc.InputBuffer input, String tag, [int offset]) {
    return new String.fromCharCodes(input.peekBytes(4, offset)) == tag;
  }
}
