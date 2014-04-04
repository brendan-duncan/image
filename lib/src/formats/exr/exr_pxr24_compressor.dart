part of image;

class ExrPxr24Compressor extends ExrCompressor {
  ExrPxr24Compressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer inPtr, int minY) {
    throw new ImageException('Pxr24 compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int minY) {
    throw new ImageException('Pxr24 compression not yet supported.');
  }

  int _maxScanLineSize;
  int _numScanLines;
}
