import '../../color/color.dart';
import '../decode_info.dart';

class JpegInfo implements DecodeInfo {
  int width = 0;
  int height = 0;
  int get numFrames => 1;
  Color? get backgroundColor => null;
}
