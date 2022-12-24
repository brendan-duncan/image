import '../../filter/pixelate.dart' as g;
import '../command.dart';

class PixelateCmd extends Command {
  int blockSize;
  g.PixelateMode mode;

  PixelateCmd(Command? input, this.blockSize,
      { this.mode = g.PixelateMode.upperLeft })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.pixelate(img, blockSize, mode: mode) : null;
  }
}
