import 'dart:typed_data';

import '../image/animation.dart';
import '../image/image.dart';

/// Base class for image format encoders.
abstract class Encoder {
  /// Encode a single image.
  Uint8List encodeImage(Image image);

  /// Does this encoder support animation?
  bool get supportsAnimation => false;

  /// Encode an animation. If the encoder does not support animation, it will
  /// encode the first frame.
  Uint8List encodeAnimation(Animation anim) =>
      anim.isNotEmpty ? encodeImage(anim[0]) : Uint8List(0);
}
