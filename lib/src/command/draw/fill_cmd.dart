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
    await input?.execute();
    final img = input?.outputImage;
    await mask?.execute();
    final maskImg = mask?.outputImage;
    outputImage = img != null ? fill(img, color, mask: maskImg,
        maskChannel: maskChannel) : null;
  }
}
