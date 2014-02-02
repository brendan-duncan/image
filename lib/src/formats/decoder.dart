part of image;

/**
 * Base class for image format decoders.  Images are always decoded to 24-bit
 * or 32-bit images, regardless of the format type.
 */
abstract class Decoder {
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
}
