import '../../filter/sepia.dart' as g;
import '../command.dart';

class SepiaCmd extends Command {
  num amount;

  SepiaCmd(Command? input, { this.amount = 100.0 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.sepia(img, amount: amount) : null;
  }
}
