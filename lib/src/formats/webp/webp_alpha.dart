part of image;


class WebPAlpha {
  int width = 0;
  int height = 0;
  int method = 0;
  int filter = 0;
  int preProcessing = 0;
  /// Although alpha channel requires only 1 byte per
  /// pixel, sometimes VP8LDecoder may need to allocate
  /// 4 bytes per pixel internally during decode.
  bool use8bDecode = false;

  WebPAlpha(this.width, this.height);

  bool init(Arc.InputStream input, int blockSize, Data.Uint8List output) {
    //const uint8_t* const alpha_data = data + ALPHA_HEADER_LEN;
    int alphaDataSize = blockSize - WebPAlpha.ALPHA_HEADER_LEN;

    int b = input.readByte();
    method = b & 0x03;
    filter = (b >> 2) & 0x03;
    preProcessing = (b >> 4) & 0x03;
    int rsrv = (b >> 6) & 0x03;

    if (method < ALPHA_NO_COMPRESSION ||
        method > ALPHA_LOSSLESS_COMPRESSION ||
        filter >= WebP.FILTER_LAST ||
        preProcessing > ALPHA_PREPROCESSED_LEVELS ||
        rsrv != 0) {
      return false;
    }

    return true;
  }

  // Alpha related constants.
  static const int ALPHA_HEADER_LEN = 1;
  static const int ALPHA_NO_COMPRESSION = 0;
  static const int ALPHA_LOSSLESS_COMPRESSION = 1;
  static const int ALPHA_PREPROCESSED_LEVELS = 1;
}
