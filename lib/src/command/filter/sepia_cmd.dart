import '../../filter/sepia.dart' as g;
import '../command.dart';

class SepiaCmd extends Command {
  num amount;

  SepiaCmd(Command? input, { this.amount = 100.0 })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.sepia(img, amount: amount) : img;
  }
}
