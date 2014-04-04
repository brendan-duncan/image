part of image;

class ExrLineBuffer {
  int dataSize = 0;
  int minY;
  int maxY;
  ExrCompressor compressor;
  int format;

  ExrLineBuffer(this.compressor) {
    format = compressor != null ? compressor.format() : ExrCompressor.XDR;
  }
}
