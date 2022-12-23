import '../../filter/emboss.dart' as g;
import '../command.dart';

class EmbossCmd extends Command {
  EmbossCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.emboss(img) : img;
  }
}
