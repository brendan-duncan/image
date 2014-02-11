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

  // APNG extensions
  int numFrames;
  int repeat;
  List<PngFrame> frames = [];

  bool get isAnimated => numFrames != null && frames.isNotEmpty;
}
