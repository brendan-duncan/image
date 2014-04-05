part of image;

class ExrZipCompressor extends ExrCompressor {
  ZLibDecoder zlib = new ZLibDecoder();

  ExrZipCompressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer input, int y) {
    throw new ImageException('Zip compression not yet supported');
    return null;
  }

  Uint8List uncompress(InputBuffer input, int y) {
    Uint8List data = zlib.decodeBytes(input.toUint8List());

    // Predictor
    for (int i = 1, len = data.length; i < len; ++i) {
      data[i] = data[i - 1] + data[i] - 128;
    }

    // Reorder the pixel data
    if (_outCache == null || _outCache.length != data.length) {
      _outCache = new Uint8List(data.length);
    }

    final int len = data.length;
    int t1 = 0;
    int t2 = (len + 1) ~/ 2;
    int si = 0;

    while (true) {
      if (si < len) {
        _outCache[si++] = data[t1++];
      } else {
        break;
      }
      if (si < len) {
        _outCache[si++] = data[t2++];
      } else {
        break;
      }
    }

    return _outCache;
  }

  int _maxScanLineSize;
  int _numScanLines;
  Uint8List _outCache;
}
