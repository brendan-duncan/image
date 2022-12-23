import '../../filter/smooth.dart' as g;
import '../command.dart';

class SmoothCmd extends Command {
  num weight;

  SmoothCmd(Command? input, this.weight)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.smooth(img, weight) : img;
  }
}
