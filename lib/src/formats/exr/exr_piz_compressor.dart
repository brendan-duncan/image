part of image;

class ExrPizCompressor extends ExrCompressor {
  ExrPizCompressor(ExrHeader header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;


  Uint8List compress(InputBuffer inPtr, int minY) {

  }

  Uint8List uncompress(InputBuffer inPtr, int minY) {

  }

  int _maxScanLineSize;
  int _numScanLines;
}
