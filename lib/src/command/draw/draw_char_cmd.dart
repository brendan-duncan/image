import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_char.dart';
import '../../font/bitmap_font.dart';
import '../command.dart';

class DrawCharCmd extends Command {
  BitmapFont font;
  int x;
  int y;
  String char;
  Color? color;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;

  DrawCharCmd(Command? input, this.char,
      {required this.font,
      required this.x,
      required this.y,
      this.color,
      this.blend = BlendMode.alpha,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawChar(img, char,
            font: font,
            x: x,
            y: y,
            color: color,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}
