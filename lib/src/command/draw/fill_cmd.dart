import '../../color/channel.dart';
import '../../color/color.dart';
import '../../draw/fill.dart';
import '../command.dart';

class FillCmd extends Command {
  Color color;
  Command? mask;
  Channel maskChannel;

  FillCmd(Command? input, this.color, { this.mask,
      this.maskChannel = Channel.luminance })
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final maskImg = await mask?.getImage();
    outputImage = img != null ? fill(img, color, mask: maskImg,
        maskChannel: maskChannel) : null;
  }
}
