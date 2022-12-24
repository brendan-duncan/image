import '../../filter/gaussian_blur.dart' as g;
import '../command.dart';

class GaussianBlurCmd extends Command {
  int radius;

  GaussianBlurCmd(Command? input, this.radius)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.gaussianBlur(img, radius) : null;
  }
}
