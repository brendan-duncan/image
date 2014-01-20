part of image;

class Animation {
  int loopCount = 0;
  int frameRate = 0;
  int backgroundColor = 0xffffffff;
  List<AnimationFrame> frames = [];

  void addFrame(Image image, [int disposalMethod = AnimationFrame.RETAIN]) {
    frames.add(new AnimationFrame(image, disposalMethod));
  }
}

class AnimationFrame {
  static const int RETAIN = 0;
  static const int CLEAR = 1;
  Image image;
  int disposalMethod = RETAIN;

  AnimationFrame(this.image, this.disposalMethod);
}
