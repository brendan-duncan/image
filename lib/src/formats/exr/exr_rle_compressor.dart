part of image;

class ExrRleCompressor extends ExrCompressor {
  ExrRleCompressor(ExrHeader header, this._maxScanLineSize) :
    super._(header) {
  }

  int numScanLines() => 1;

  Uint8List compress(InputBuffer inPtr, int minY) {

  }

  Uint8List uncompress(InputBuffer inPtr, int minY) {

  }

  int _maxScanLineSize;
}
