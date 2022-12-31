import '../../transform/copy_crop.dart';
import '../command.dart';

class CopyCropCmd extends Command {
  int x;
  int y;
  int width;
  int height;

  CopyCropCmd(Command? input,
      {required this.x,
      required this.y,
      required this.width,
      required this.height})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyCrop(img, x: x, y: y, width: width, height: height)
        : null;
  }
}
