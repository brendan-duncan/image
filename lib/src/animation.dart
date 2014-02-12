part of image;

/**
 * A serries of images comprising an animated sequence.
 */
class Animation extends IterableBase<Image> {
  /// How many times should the animation loop (0 means forever)?
  int loopCount = 0;
  /// The suggested background color to use for transparency compositing.
  int backgroundColor = 0xffffffff;
  /// The frames of the animation.
  List<Image> frames = [];

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
  Image operator[](int index) => frames[index];

  /**
   * Add a frame to the animation.
   */
  void addFrame(Image image) {
    frames.add(image);
  }

  /**
   * The first frame of the animation.
   */
  Image get first => frames.first;

  /**
   * The last frame of the animation.
   */
  Image get last => frames.last;

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
  Iterator<Image> get iterator => frames.iterator;
}
