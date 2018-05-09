import '../animation.dart';
import '../image.dart';
import 'decoder.dart';
import 'decode_info.dart';
import 'psd/psd_image.dart';

/**
 * Decode a Photoshop PSD image.
 */
class PsdDecoder extends Decoder {
  PsdImage info;

  /**
   * A light-weight function to test if the given file is able to be decoded
   * by this Decoder.
   */
  bool isValidFile(List<int> bytes) {
    return new PsdImage(bytes).isValid;
  }

  /**
   * Decode a raw PSD image without rendering it to a flat image.
   */
  PsdImage decodePsd(List<int> bytes) {
    PsdImage psd = new PsdImage(bytes);
    if (!psd.decode()) {
      return null;
    }
    return psd;
  }

  /**
   * Decode the file and extract a single image from it.  If the file is
   * animated, the specified [frame] will be decoded.  If there was a problem
   * decoding the file, null is returned.
   */
  Image decodeImage(List<int> bytes, {int frame: 0}) {
    startDecode(bytes);
    return decodeFrame(frame);
  }

  /**
   * Decode all of the frames from an animation.  If the file is not an
   * animation, a single frame animation is returned.  If there was a problem
   * decoding the file, null is returned.
   */
  Animation decodeAnimation(List<int> bytes) {
    if (startDecode(bytes) == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.width = info.width;
    anim.height = info.height;
    anim.frameType = Animation.PAGE;
    for (int i = 0, len = numFrames(); i < len; ++i) {
      Image image = decodeFrame(i);
      if (i == null) {
        continue;
      }
      anim.addFrame(image);
    }

    return anim;
  }

  /**
   * Start decoding the data as an animation sequence, but don't actually
   * process the frames until they are requested with decodeFrame.
   */
  DecodeInfo startDecode(List<int> bytes) {
    info = new PsdImage(bytes);
    return info;
  }

  /**
   * How many frames are available to be decoded.  [startDecode] should have
   * been called first. Non animated image files will have a single frame.
   */
  int numFrames() => info != null ? info.numFrames : 0;

  /**
   * Decode a single frame from the data stat was set with [startDecode].
   * If [frame] is out of the range of available frames, null is returned.
   * Non animated image files will only have [frame] 0.  An [AnimationFrame]
   * is returned, which provides the image, and top-left coordinates of the
   * image, as animated frames may only occupy a subset of the canvas.
   */
  Image decodeFrame(int frame) {
    if (info == null) {
      return null;
    }
    return info.decodeImage();
  }
}
