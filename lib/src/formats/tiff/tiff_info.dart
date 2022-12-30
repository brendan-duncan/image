import '../../color/color.dart';
import '../../formats/decode_info.dart';
import 'tiff_image.dart';

class TiffInfo implements DecodeInfo {
  int width = 0;
  int height = 0;
  bool? bigEndian;
  int? signature;

  int? ifdOffset;
  List<TiffImage> images = [];

  int get numFrames => images.length;

  Color? get backgroundColor => null;
}
