import '../../internal/internal.dart';

/**
 * Decodes a frame from a PNG animation.
 */
class PngFrame {
  // DisposeMode
  static const int APNG_DISPOSE_OP_NONE = 0;
  static const int APNG_DISPOSE_OP_BACKGROUND = 1;
  static const int APNG_DISPOSE_OP_PREVIOUS = 2;
  // BlendMode
  static const int APNG_BLEND_OP_SOURCE = 0;
  static const int APNG_BLEND_OP_OVER = 1;

  int sequenceNumber;
  int width;
  int height;
  int xOffset;
  int yOffset;
  int delayNum;
  int delayDen;
  int dispose;
  int blend;

  List<int> _fdat = [];
}

@internal
class InternalPngFrame extends PngFrame {
  List<int> get fdat => _fdat;
}
