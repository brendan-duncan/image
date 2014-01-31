part of image;

class Animation {
  int loopCount = 0;
  int frameRate = 0;
  int backgroundColor = 0xffffffff;
  List<AnimationFrame> frames = [];

  int get numFrames => frames.length;

  AnimationFrame operator[](int index) => frames[index];

  void addFrame(Image image, [int duration = 80]) {
    frames.add(new AnimationFrame(image, duration));
  }
}

class AnimationFrame {
  Image image;
  // duration of the frame, in milliseconds.
  int duration;

  AnimationFrame(this.image, this.duration);
}
