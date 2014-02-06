part of image;


/**
 * Features gathered from the bitstream
 */
class WebPInfo {
  // enum Format
  static const int FORMAT_UNDEFINED = 0;
  static const int FORMAT_LOSSY = 1;
  static const int FORMAT_LOSSLESS = 2;
  static const int FORMAT_ANIMATED = 3;

  /// Width in pixels, as read from the bitstream.
  int width = 0;
  /// Height in pixels, as read from the bitstream.
  int height = 0;
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
  /// The color to use for the animation background.
  int animBackgroundColor = 0;
  /// How many times the animation should loop.
  int animLoopCount = 0;
  /// Information about each animation frame.
  List<WebPFrame> frames = [];

  int get numFrames => frames.length;

  InputStream _alphaData;
  int _alphaSize;
  int _vp8Position;
  int _vp8Size;
}
