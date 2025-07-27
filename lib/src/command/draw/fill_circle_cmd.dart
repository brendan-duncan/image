import '../../../image.dart';

class FillCircleCmd extends Command {
  int x;
  int y;
  int radius;
  Color color;
  bool antialias;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;

  FillCircleCmd(Command? input,
      {required this.x,
      required this.y,
      required this.radius,
      required this.color,
      this.antialias = false,
      this.blend = BlendMode.alpha,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? fillCircle(img,
            x: x,
            y: y,
            radius: radius,
            color: color,
            antialias: antialias,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}
