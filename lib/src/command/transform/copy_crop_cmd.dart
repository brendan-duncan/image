import '../../transform/copy_crop.dart';
import '../command.dart';

class CopyCropCmd extends Command {
  int x;
  int y;
  int w;
  int h;

  CopyCropCmd(Command? input, this.x, this.y, this.w, this.h)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? copyCrop(img, x, y, w, h) : null;
  }
}
