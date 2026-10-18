import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_polygon.dart';
import '../../util/point.dart';
import '../command.dart';

class DrawPolygonCmd extends Command {
  List<Point> vertices;
  Color color;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;
  bool linearBlend;

  DrawPolygonCmd(Command? input,
      {required this.vertices,
      required this.color,
      this.blend = BlendMode.alpha,
      this.mask,
      this.maskChannel = Channel.luminance,
      this.linearBlend = false})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawPolygon(img,
            vertices: vertices,
            color: color,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel,
            linearBlend: linearBlend)
        : null;
  }
}
