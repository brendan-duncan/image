import '../../filter/grayscale.dart' as g;
import '../command.dart';

class GrayscaleCmd extends Command {
  GrayscaleCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.grayscale(img) : null;
  }
}
