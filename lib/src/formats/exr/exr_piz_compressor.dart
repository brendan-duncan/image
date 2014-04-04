part of image;

class ExrPizCompressor extends ExrCompressor {
  ExrPizCompressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;


  Uint8List compress(InputBuffer inPtr, int minY) {
    throw new ImageException('Piz compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int minY) {
    throw new ImageException('Piz compression not yet supported.');
  }

  int _maxScanLineSize;
  int _numScanLines;
}
