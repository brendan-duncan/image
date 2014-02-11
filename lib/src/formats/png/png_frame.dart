part of image;

/**
 * Decodes a frame from a PNG animation.
 */
class PngFrame {
  int sequenceNumber;
  int width;
  int height;
  int xOffset;
  int yOffset;
  int delayNum;
  int delayDen;
  int dispose;
  int blend;

  int _framePosition;
  int _frameSize;
}

