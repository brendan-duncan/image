part of image;

/**
 * A serries of images comprising an animated sequence.
 */
class Animation extends IterableBase<AnimationFrame> {
  int loopCount = 0;
  int frameRate = 0;
  int backgroundColor = 0xffffffff;
  List<AnimationFrame> frames = [];

  int get numFrames => frames.length;

  int get length => frames.length;

  AnimationFrame operator[](int index) => frames[index];

  void addFrame(Image image, [int duration = 80]) {
    frames.add(new AnimationFrame(image, duration));
  }

  AnimationFrame get first => frames.first;

  AnimationFrame get last => frames.last;

  bool get isEmpty => frames.isEmpty;

  // Returns true if there is at least one element in this collection.
  bool get isNotEmpty => frames.isNotEmpty;

  Iterator<AnimationFrame> get iterator => frames.iterator;
}

/**
 * A frame in an [Animation].
 */
class AnimationFrame {
  Image image;
  // duration of the frame, in milliseconds.
  int duration;

  AnimationFrame(this.image, this.duration);
}
