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
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? trim(img, mode: mode, sides: sides) : null;
  }
}
