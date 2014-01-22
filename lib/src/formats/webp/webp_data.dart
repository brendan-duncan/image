part of image;


/**
 * Features gathered from the bitstream
 */
class WebPData {
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
  String iccp = '';
  String exif = '';
  String xmp = '';
  int animBackgroundColor = 0;
  int animLoopCount = 0;

  int _alphaPosition;
  int _alphaSize;
  int _vp8Position;
  int _vp8Size;
  List<int> _animPositions = [];
  List<int> _animSizes = [];
}
