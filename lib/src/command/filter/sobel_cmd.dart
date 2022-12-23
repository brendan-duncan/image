import '../../filter/sobel.dart' as g;
import '../command.dart';

class SobelCmd extends Command {
  num amount;

  SobelCmd(Command? input, { this.amount = 100.0 })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.sobel(img, amount: amount) : img;
  }
}
