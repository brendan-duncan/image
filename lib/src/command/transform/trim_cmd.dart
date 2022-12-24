import '../../transform/trim.dart';
import '../command.dart';

class TrimCmd extends Command {
  TrimMode mode;
  Trim sides;

  TrimCmd(Command? input, { this.mode = TrimMode.transparent,
      this.sides = Trim.all })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? trim(img, mode: mode, sides: sides) : null;
  }
}
