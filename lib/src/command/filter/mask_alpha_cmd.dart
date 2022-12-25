import '../../color/channel.dart';
import '../../filter/mask_alpha.dart' as g;
import '../command.dart';

class MaskAlphaCmd extends Command {
  final Command? _mask;
  final Channel maskChannel;
  final bool scaleMask;

  MaskAlphaCmd(Command? input, this._mask,
      { this.maskChannel = Channel.luminance, this.scaleMask = false })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    _mask?.execute();
    final maskImg = _mask?.outputImage;
    outputImage = img != null && maskImg != null ?
        g.maskAlpha(img, maskImg, maskChannel: maskChannel,
            scaleMask: scaleMask)
        : null;
  }
}
