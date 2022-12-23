import '../../filter/grayscale.dart' as g;
import '../command.dart';

class GrayscaleCmd extends Command {
  GrayscaleCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.grayscale(img) : img;
  }
}
