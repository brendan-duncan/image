import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/fill_rect.dart';
import '../command.dart';

class FillRectCmd extends Command {
  int x1;
  int y1;
  int x2;
  int y2;
  Color c;
  Command? mask;
  Channel maskChannel;

  FillRectCmd(Command? input, this.x1, this.y1, this.x2, this.y2, this.c,
      { this.mask, this.maskChannel = Channel.luminance })
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null ? fillRect(img, x1, y1, x2, y2, c,
        mask: maskImg, maskChannel: maskChannel) : null;
  }
}
