import '../../../image.dart';

class FillPolygonCmd extends Command {
  List<Point> vertices;
  Color color;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;

  FillPolygonCmd(Command? input,
      {required this.vertices,
      required this.color,
      this.blend = BlendMode.alpha,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? fillPolygon(img,
            vertices: vertices,
            color: color,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}
