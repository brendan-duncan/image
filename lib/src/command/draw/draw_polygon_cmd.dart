import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_polygon.dart';
import '../../util/point.dart';
import '../command.dart';

class DrawPolygonCmd extends Command {
  List<Point> vertices;
  Color color;
  bool antialias;
  num thickness;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;
  bool linearBlend;

  DrawPolygonCmd(Command? input,
      {required this.vertices,
      required this.color,
      this.antialias = false,
      this.thickness = 1,
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
            antialias: antialias,
            thickness: thickness,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel,
            linearBlend: linearBlend)
        : null;
  }
}
