part of image;


class WebPAlpha {
  Arc.InputStream input;
  int width = 0;
  int height = 0;
  int method = 0;
  int filter = 0;
  int preProcessing = 0;
  int rsrv = 1;
  bool isAlphaDecoded = false;

  WebPAlpha(this.input, this.width, this.height) {
    int b = input.readByte();
    method = b & 0x03;
    filter = (b >> 2) & 0x03;
    preProcessing = (b >> 4) & 0x03;
    rsrv = (b >> 6) & 0x03;

    if (isValid) {
      if (method == ALPHA_NO_COMPRESSION) {
        final int alphaDecodedSize = width * height;
        if (input.remainder < alphaDecodedSize) {
          rsrv = 1;
        }
      } else if (method == ALPHA_LOSSLESS_COMPRESSION) {
        if (!_decodeAlphaHeader()) {
          rsrv = 1;
        }
      } else {
        rsrv = 1;
      }
    }
  }

  bool get isValid {
    if (method < ALPHA_NO_COMPRESSION ||
        method > ALPHA_LOSSLESS_COMPRESSION ||
        filter >= WebPFilters.FILTER_LAST ||
        preProcessing > ALPHA_PREPROCESSED_LEVELS ||
        rsrv != 0) {
      return false;
    }
    return true;
  }

  bool decode(int row, int numRows, Data.Uint8List output) {
    if (!isValid) {
      return false;
    }

    var unfilterFunc = WebPFilters.UNFILTERS[filter];

    if (method == ALPHA_NO_COMPRESSION) {
      final int offset = row * width;
      final int numPixels = numRows * width;

      output.setRange(offset, numPixels, input.buffer,
                      input.position + offset);
    } else {
      if (!_decodeAlphaImageStream(row + numRows, output)) {
        return false;
      }
    }

    if (unfilterFunc != null) {
      unfilterFunc(width, height, width, row, numRows, output);
    }

    if (preProcessing == ALPHA_PREPROCESSED_LEVELS) {
      if (!_dequantizeLevels(output, width, height, row, numRows)) {
        return false;
      }
    }

    if (row + numRows == height) {
      isAlphaDecoded = true;
    }

    return true;
  }

  bool _dequantizeLevels(Data.Uint8List data, int width, int height,
                         int row, int num_rows) {
    if (data == null || width <= 0 || height <= 0 || row < 0 || num_rows < 0 ||
        row + num_rows > height) {
      return false;
    }
    return true;
  }


  bool _decodeAlphaImageStream(int lastRow, Data.Uint8List output) {
    _vp8l._opaque = output;
    // Decode (with special row processing).
    return _use8bDecode ?
        _vp8l._decodeAlphaData(0, width, height, lastRow) :
        _vp8l._decodeImageData(_vp8l._pixels, width, height,
                               lastRow, _vp8l._extractAlphaRows);
  }

  bool _decodeAlphaHeader() {
    WebPInfo webp = new WebPInfo();
    webp.width = width;
    webp.height = height;

    _vp8l = new VP8L(input, webp);

    _vp8l._decodeImageStream(webp.width, webp.height, true);

    // Special case: if alpha data uses only the color indexing transform and
    // doesn't use color cache (a frequent case), we will use DecodeAlphaData()
    // method that only needs allocation of 1 byte per pixel (alpha channel).
    if (_vp8l._transforms.length == 1 &&
        _vp8l._transforms[0].type == VP8LTransform.COLOR_INDEXING_TRANSFORM &&
        _vp8l._is8bOptimizable()) {
      _use8bDecode = true;
      _vp8l._allocateInternalBuffers8b();
    } else {
      _use8bDecode = false;
      _vp8l._allocateInternalBuffers32b();
    }

    return true;
  }

  VP8L _vp8l;
  /// Although alpha channel
  /// requires only 1 byte per
  /// pixel, sometimes VP8LDecoder may need to allocate
  /// 4 bytes per pixel internally during decode.
  bool _use8bDecode = false;

  // Alpha related constants.
  static const int ALPHA_NO_COMPRESSION = 0;
  static const int ALPHA_LOSSLESS_COMPRESSION = 1;
  static const int ALPHA_PREPROCESSED_LEVELS = 1;
}
