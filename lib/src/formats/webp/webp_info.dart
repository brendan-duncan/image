part of image;


/**
 * Features gathered from the bitstream
 */
class WebPInfo extends DecodeInfo {
  // enum Format
  static const int FORMAT_UNDEFINED = 0;
  static const int FORMAT_LOSSY = 1;
  static const int FORMAT_LOSSLESS = 2;
  static const int FORMAT_ANIMATED = 3;

  /// True if the bitstream contains an alpha channel.
  bool hasAlpha = false;
  /// True if the bitstream is an animation.
  bool hasAnimation = false;
  /// 0 = undefined (/mixed), 1 = lossy, 2 = lossless, 3 = animated
  int format = FORMAT_UNDEFINED;
  /// ICCP data string.
  String iccp = '';
  /// EXIF data string.
  String exif = '';
  /// XMP data string.
  String xmp = '';
  /// How many times the animation should loop.
  int animLoopCount = 0;
  /// Information about each animation frame.
  List<WebPFrame> frames = [];

  ProgressCallback progressCallback;
  int _frame;
  int _numFrames;

  InputStream _alphaData;
  int _alphaSize;
  int _vp8Position;
  int _vp8Size;
}
