import '../../filter/gaussian_blur.dart' as g;
import '../command.dart';

class GaussianBlurCmd extends Command {
  int radius;

  GaussianBlurCmd(Command? input, this.radius)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.gaussianBlur(img, radius) : img;
  }
}
