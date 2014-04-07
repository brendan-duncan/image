part of image;

class ExrB44Compressor extends ExrCompressor {
  ExrB44Compressor(ExrPart header, this._maxScanLineSize, this._numScanLines,
                   this._optFlatFields) :
    super._(header) {
  }

  int numScanLines() => _numScanLines;


  Uint8List compress(InputBuffer inPtr, int x, int y,
                     [int width, int height]) {
    throw new ImageException('B44 compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int x, int y,
                       [int width, int height]) {
    throw new ImageException('B44 compression not yet supported.');
  }

  int _maxScanLineSize;
  int _numScanLines;
  bool _optFlatFields;
}
