import '../../filter/chromatic_aberration.dart';
import '../command.dart';

class ChromaticAberrationCmd extends Command {
  int shift;
  ChromaticAberrationCmd(Command? input, { this.shift = 5 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? chromaticAberration(img, shift: shift) : null;
  }
}
