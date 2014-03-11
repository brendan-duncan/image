part of image;

class TgaInfo extends DecodeInfo {
  /// The number of frames that can be decoded.
  int get numFrames => 1;

  /// Offset in the input file the image data starts at.
  int imageOffset;
}
