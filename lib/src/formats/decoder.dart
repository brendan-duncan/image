part of image;

/**
 * A callback called during the decoding process.
 */
typedef void ProgressCallback(int frame, int numFrames,
                              int progress, int total);

/**
 * Base class for image format decoders.  Images are always decoded to 24-bit
 * or 32-bit images, regardless of the format type.
 */
abstract class Decoder {
  ProgressCallback progressCallback;

  /**
   * A light-weight function to test if the given file is able to be decoded
   * by this Decoder.
   */
  bool isValidFile(List<int> bytes);

  /**
   * Decode the file and extract a single image from it.  If the file is
   * animated, the specified [frame] will be decoded.  If there was a problem
   * decoding the file, null is returned.
   */
  Image decodeImage(List<int> bytes, {int frame: 0});

  /**
   * Decode all of the frames from an animation.  If the file is not an
   * animation, a single frame animation is returned.  If there was a problem
   * decoding the file, null is returned.
   */
  Animation decodeAnimation(List<int> bytes);

  /**
   * Start decoding the data as an animation sequence, but don't actually
   * process the frames until they are requested with decodeFrame.
   */
  DecodeInfo startDecode(List<int> bytes);

  /**
   * How many frames are available to be decoded.  [startDecode] should have
   * been called first. Non animated image files will have a single frame.
   */
  int numFrames();

  /**
   * Decode a single frame from the data stat was set with [startDecode].
   * If [frame] is out of the range of available frames, null is returned.
   * Non animated image files will only have [frame] 0.  An [AnimationFrame]
   * is returned, which provides the image, and top-left coordinates of the
   * image, as animated frames may only occupy a subset of the canvas.
   */
  Image decodeFrame(int frame);
}
