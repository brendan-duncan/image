import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_string.dart';
import '../../font/bitmap_font.dart';
import '../command.dart';

class DrawStringCmd extends Command {
  BitmapFont font;
  int? x;
  int? y;
  String string;
  bool rightJustify;
  bool wrap;
  Color? color;
  BlendMode blend;
  Command? mask;
  Channel maskChannel;

  DrawStringCmd(Command? input, this.string,
      {required this.font,
      this.x,
      this.y,
      this.color,
      this.wrap = false,
      this.rightJustify = false,
      this.blend = BlendMode.alpha,
      this.mask,
      this.maskChannel = Channel.luminance})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null
        ? drawString(img, string,
            font: font,
            x: x,
            y: y,
            color: color,
            rightJustify: rightJustify,
            wrap: wrap,
            blend: blend,
            mask: maskImg,
            maskChannel: maskChannel)
        : null;
  }
}
