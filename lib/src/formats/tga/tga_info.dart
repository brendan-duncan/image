import '../../color/color.dart';
import '../decode_info.dart';

class TgaInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;

  @override
  int get numFrames => 1;
  @override
  Color? get backgroundColor => null;

  // Offset in the input file the image data starts at.
  int? imageOffset;

  // Bits per pixel.
  int? bpp;
}
