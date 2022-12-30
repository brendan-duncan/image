import '../../color/color.dart';
import '../decode_info.dart';
import 'gif_color_map.dart';
import 'gif_image_desc.dart';

class GifInfo implements DecodeInfo {
  int width = 0;
  int height = 0;
  Color? backgroundColor = null;

  int colorResolution = 0;
  GifColorMap? globalColorMap;
  bool isGif89 = false;
  List<GifImageDesc> frames = [];

  @override
  int get numFrames => frames.length;
}
