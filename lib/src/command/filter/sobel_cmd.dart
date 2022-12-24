import '../../filter/sobel.dart' as g;
import '../command.dart';

class SobelCmd extends Command {
  num amount;

  SobelCmd(Command? input, { this.amount = 100.0 })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.sobel(img, amount: amount) : null;
  }
}
