import '../../filter/emboss.dart' as g;
import '../command.dart';

class EmbossCmd extends Command {
  EmbossCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.emboss(img) : null;
  }
}
