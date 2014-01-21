part of image;


/**
 * Features gathered from the bitstream
 */
class WebPData {
  /// Width in pixels, as read from the bitstream.
  int width = 0;
  /// Height in pixels, as read from the bitstream.
  int height = 0;
  /// True if the bitstream contains an alpha channel.
  bool hasAlpha = false;
  /// True if the bitstream is an animation.
  bool hasAnimation = false;
  /// 0 = undefined (/mixed), 1 = lossy, 2 = lossless
  int format = 0;
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
