enum BlendMode {
  /// No alpha blending should be done when drawing this frame (replace
  /// pixels in canvas).
  source,

  /// Alpha blending should be used when drawing this frame (composited over
  /// the current canvas image).
  over
}

enum DisposeMode {
  /// When drawing a frame, the canvas should be left as it is.
  none,

  /// When drawing a frame, the canvas should be cleared first.
  clear,

  /// When drawing this frame, the canvas should be reverted to how it was
  /// before drawing it.
  previous
}

class FrameInfo {
  /// The index of the frame in the Animation container.
  int index;

  /// x position at which to render the frame. This is used for frames
  /// in an animation, such as from an animated GIF.
  int xOffset;

  /// y position at which to render the frame. This is used for frames
  /// in an animation, such as from an animated GIF.
  int yOffset;

  /// How long this frame should be displayed, in milliseconds.
  /// A duration of 0 indicates no delay and the next frame will be drawn
  /// as quickly as it can.
  int duration;

  /// Defines what should be done to the canvas when drawing this frame
  /// in an animation.
  DisposeMode disposeMethod;

  /// Defines the blending method (alpha compositing) to use when drawing this
  /// frame in an animation.
  BlendMode blendMethod;

  FrameInfo()
      : index = 0
      , xOffset = 0
      , yOffset = 0
      , duration = 0
      , disposeMethod = DisposeMode.clear
      , blendMethod = BlendMode.over;

  FrameInfo.from(FrameInfo other)
      : index = 0
      , xOffset = other.xOffset
      , yOffset = other.yOffset
      , duration = other.duration
      , disposeMethod = other.disposeMethod
      , blendMethod = other.blendMethod;

  FrameInfo clone() => FrameInfo.from(this);

  void copy(FrameInfo other) {
    index = other.index;
    xOffset = other.xOffset;
    yOffset = other.yOffset;
    duration = other.duration;
    disposeMethod = other.disposeMethod;
    blendMethod = other.blendMethod;
  }
}
