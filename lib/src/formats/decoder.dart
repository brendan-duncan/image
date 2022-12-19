import 'dart:typed_data';

import '../image/animation.dart';
import '../image/image.dart';
import 'decode_info.dart';

/// Base class for image format decoders.
///
/// Image pixels are stored as 32-bit unsigned ints, so all formats, regardless
/// of their encoded color resolutions, decode to 32-bit RGBA images. Encoders
/// can reduce the color resolution back down to their required formats.
///
/// Some image formats support multiple frames, often for encoding animation.
/// In such cases, the [decodeImage] method will decode the first (or otherwise
/// specified with the frame parameter) frame of the file. [decodeAnimation]
/// will decode all frames from the image. [startDecode] will initiate
/// decoding of the file, and [decodeFrame] will then decode a specific frame
/// from the file, allowing for animations to be decoded one frame at a time.
/// Some formats, such as TIFF, may store multiple frames, but their use of
/// frames is for multiple page documents and not animation. The terms
/// 'animation' and 'frames' simply refer to 'pages' in this case.
///
/// If an image file does not have multiple frames, [decodeAnimation] and
/// [startDecode]/[decodeFrame] will return the single image of the
/// file. As such, if you are not sure if a file is animated or not, you can
/// use the animated functions and process it as a single frame image if it
/// has only 1 frame, and as an animation if it has more than 1 frame.
abstract class Decoder {
  /// A light-weight function to test if the given file is able to be decoded
  /// by this Decoder.
  bool isValidFile(Uint8List bytes);

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  Image? decodeImage(Uint8List bytes, {int frame = 0});

  /// Decode all of the frames from an animation. If the file is not an
  /// animation, a single frame animation is returned. If there was a problem
  /// decoding the file, null is returned.
  Animation? decodeAnimation(Uint8List bytes);

  /// Start decoding the data as an animation sequence, but don't actually
  /// process the frames until they are requested with decodeFrame.
  DecodeInfo? startDecode(Uint8List bytes);

  /// How many frames are available to be decoded. [startDecode] should have
  /// been called first. Non animated image files will have a single frame.
  int numFrames();

  /// Decode a single frame from the data that was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An [Image]
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  Image? decodeFrame(int frame);
}
