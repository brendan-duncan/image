part of image;

class ExrPxr24Compressor extends ExrCompressor {
  ExrPxr24Compressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer inPtr, int y) {
    throw new ImageException('Pxr24 compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int y) {
    List<int> data = _zlib.decodeBytes(inPtr.toUint8List());
    if (data == null) {
      throw new ImageException('Error decoding pxr24 compressed data');
    }

    if (_outCache == null) {
      _outCache = new OutputBuffer(size: _numScanLines * _maxScanLineSize);
    }
    _outCache.rewind();

    int tmpEnd = 0;
    List<int> ptr = [0, 0, 0, 0];
    Uint32List pixel = new Uint32List(1);
    Uint8List pixelBytes = new Uint8List.view(pixel.buffer);

    int numChannels = _header.channels.length;
    for (int yi = 0; yi < _header._linesInBuffer; ++yi) {
      if (y + yi >= _header.height) {
        break;
      }

      for (int ci = 0; ci < numChannels; ++ci) {
        ExrChannel ch = _header.channels[ci];
        int n = _numSamples(ch.xSampling, 0, _header.width);
        pixel[0] = 0;

        switch (ch.type) {
          case ExrChannel.TYPE_UINT:
            break;
          case ExrChannel.TYPE_HALF:
            break;
          case ExrChannel.TYPE_FLOAT:
            ptr[0] = tmpEnd;
            ptr[1] = ptr[0] + n;
            ptr[2] = ptr[1] + n;
            tmpEnd = ptr[2] + n;
            for (int j = 0; j < n; ++j) {
              int diff = (data[ptr[0]++] << 24) |
                         (data[ptr[1]++] << 16) |
                         (data[ptr[2]++] << 8);
              pixel[0] += diff;
              for (int k = 0; k < 4; ++k) {
                _outCache.writeByte(pixelBytes[k]);
              }
            }
            break;
        }
      }
    }

    return _outCache.getBytes();
  }

  ZLibDecoder _zlib = new ZLibDecoder();
  int _maxScanLineSize;
  int _numScanLines;
  OutputBuffer _outCache;
}
