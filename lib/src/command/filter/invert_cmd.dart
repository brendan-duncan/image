import '../../filter/invert.dart' as g;
import '../command.dart';

class InvertCmd extends Command {
  InvertCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.invert(img) : null;
  }
}
