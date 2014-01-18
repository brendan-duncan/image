part of image;


/**
 * Features gathered from the bitstream
 */
class WebPFeatures {
  /// Width in pixels, as read from the bitstream.
  int width = 0;
  /// Height in pixels, as read from the bitstream.
  int height = 0;
  /// True if the bitstream contains an alpha channel.
  bool hasAlpha = false;
  /// True if the bitstream is an animation.
  bool hasAanimation = false;
  /// 0 = undefined (/mixed), 1 = lossy, 2 = lossless
  int format = 0;
}
