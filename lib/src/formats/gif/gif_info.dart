part of image;

class GifInfo extends DecodeInfo {
  int colorResolution = 0;
  GifColorMap globalColorMap;
  bool isGif89 = false;
  List<GifImageDesc> frames = [];

  int get numFrames => frames.length;
}
