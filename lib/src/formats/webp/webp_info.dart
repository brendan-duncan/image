import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';
import 'webp_frame.dart';

/// Features gathered from the bitstream
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

  int get numFrames => frames.length;

  int _frame;
  int _numFrames;

  InputBuffer _alphaData;
  int _alphaSize;
  int _vp8Position;
  int _vp8Size;
}

@internal
class InternalWebPInfo extends WebPInfo {
  int get frame => _frame;
  set frame(int value) => _frame = value;

  int get numFrames => _numFrames;
  set numFrames(int value) => _numFrames = value;

  InputBuffer get alphaData => _alphaData;
  set alphaData(InputBuffer buffer) => _alphaData = buffer;

  int get alphaSize => _alphaSize;
  set alphaSize(int value) => _alphaSize = value;

  int get vp8Position => _vp8Position;
  set vp8Position(int value) => _vp8Position = value;

  int get vp8Size => _vp8Size;
  set vp8Size(int value) => _vp8Size = value;
}
