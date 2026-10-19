import '../../transform/trim.dart';
import '../command.dart';

class TrimCmd extends Command {
  TrimMode mode;
  Trim sides;
  num fuzzy;
  int padding;

  TrimCmd(Command? input,
      {this.mode = TrimMode.transparent,
      this.sides = Trim.all,
      this.fuzzy = 0,
      this.padding = 0})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? trim(img, mode: mode, sides: sides, fuzzy: fuzzy, padding: padding)
        : null;
  }
}
