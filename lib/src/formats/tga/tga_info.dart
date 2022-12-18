import '../../color/color.dart';
import '../decode_info.dart';

class TgaInfo implements DecodeInfo {
  int width = 0;
  int height = 0;

  int get numFrames => 1;
  Color? get backgroundColor => null;

  // Offset in the input file the image data starts at.
  int? imageOffset;

  // Bits per pixel.
  int? bpp;
}
