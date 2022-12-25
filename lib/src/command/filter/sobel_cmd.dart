import '../../filter/sobel.dart' as g;
import '../command.dart';

class SobelCmd extends Command {
  num amount;

  SobelCmd(Command? input, { this.amount = 1.0 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.sobel(img, amount: amount) : null;
  }
}
