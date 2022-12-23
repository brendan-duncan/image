import '../../filter/pixelate.dart' as g;
import '../command.dart';

class PixelateCmd extends Command {
  int blockSize;
  g.PixelateMode mode;

  PixelateCmd(Command? input, this.blockSize,
      { this.mode = g.PixelateMode.upperLeft })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.pixelate(img, blockSize, mode: mode) : img;
  }
}
