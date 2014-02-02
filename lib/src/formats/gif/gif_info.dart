part of image;

class GifInfo {
  int width = 0;
  int height = 0;
  int colorResolution = 0;
  int backgroundColor = 0;
  GifColorMap globalColorMap;
  bool isGif89 = false;
  List<GifImageDesc> frames = [];

  int get numFrames => frames.length;
}
