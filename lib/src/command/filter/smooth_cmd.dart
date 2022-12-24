import '../../filter/smooth.dart' as g;
import '../command.dart';

class SmoothCmd extends Command {
  num weight;

  SmoothCmd(Command? input, this.weight)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.smooth(img, weight) : null;
  }
}
