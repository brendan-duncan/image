import '../../filter/invert.dart' as g;
import '../command.dart';

class InvertCmd extends Command {
  InvertCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.invert(img) : img;
  }
}
