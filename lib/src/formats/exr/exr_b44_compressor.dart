part of image;

class ExrB44Compressor extends ExrCompressor {
  ExrB44Compressor(ExrHeader header, this._maxScanLineSize, this._numScanLines,
                   this._optFlatFields) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;


  Uint8List compress(InputBuffer inPtr, int minY) {

  }

  Uint8List uncompress(InputBuffer inPtr, int minY) {

  }

  int _maxScanLineSize;
  int _numScanLines;
  bool _optFlatFields;
}
