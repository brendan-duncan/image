part of image;

/**
 * A serries of images comprising an animated sequence.
 */
class Animation extends IterableBase<AnimationFrame> {
  /// How many times should the animation loop (0 means forever)?
  int loopCount = 0;
  /// The suggested background color to use for transparency compositing.
  int backgroundColor = 0xffffffff;
  /// The frames of the animation.
  List<AnimationFrame> frames = [];

  /**
   * How many frames are in the animation?
   */
  int get numFrames => frames.length;

  /**
   * How many frames are in the animation?
   */
  int get length => frames.length;

  /**
   * Get the frame at the given [index].
   */
  AnimationFrame operator[](int index) => frames[index];

  /**
   * Add a frame to the animation.
   */
  void addFrame(Image image, [int duration = 80]) {
    frames.add(new AnimationFrame(image, duration));
  }

  /**
   * The first frame of the animation.
   */
  AnimationFrame get first => frames.first;

  /**
   * The last frame of the animation.
   */
  AnimationFrame get last => frames.last;

  /**
   * Is the animation empty (no frames)?
   */
  bool get isEmpty => frames.isEmpty;

  /**
   * Returns true if there is at least one frame in the animation.
   */
  bool get isNotEmpty => frames.isNotEmpty;

  /**
   * Get the iterator for looping over the animation.  This allows the
   * Animation to be used in for-each loops:
   * for (AnimationFrame frame in animation) { ... }
   */
  Iterator<AnimationFrame> get iterator => frames.iterator;
}

/**
 * A frame in an [Animation].
 */
class AnimationFrame {
  /// The image of the frame.
  Image image;
  /// How long this frame should be displayed, in milliseconds.
  /// A duration of 0 indicates no delay and the next frame will be drawn
  /// as quickly as it can.
  int duration;
  /// The left [x] coordiante of this frame.
  int x = 0;
  /// The top [y] coordinate of this frame.
  int y = 0;
  /// Should the canvas be cleared prior to drawing this frame?
  bool clear = true;

  AnimationFrame(this.image, [this.duration = 80]);
}
