part of image;

class PngInfo extends DecodeInfo {
  int bits;
  int colorType;
  int compressionMethod;
  int filterMethod;
  int interlaceMethod;
  List<int> palette;
  List<int> transparency;
  List<int> colorLut;
  double gamma;
  int backgroundColor = 0x00ffffff;

  // APNG extensions
  int numFrames = 1;
  int repeat = 0;
  List<PngFrame> frames = [];

  List<int> _idat = [];

  bool get isAnimated => frames.isNotEmpty;
}
