import '../../color/channel.dart';
import '../../filter/image_mask.dart' as g;
import '../command.dart';

class ImageMaskCmd extends Command {
  final Command? _mask;
  final Channel maskChannel;
  final bool scaleMask;

  ImageMaskCmd(Command? input, this._mask,
      { this.maskChannel = Channel.luminance, this.scaleMask = false })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    _mask?.execute();
    final maskImg = _mask?.outputImage;
    outputImage = img != null && maskImg != null ?
        g.imageMask(img, maskImg, maskChannel: maskChannel,
            scaleMask: scaleMask)
        : null;
  }
}
