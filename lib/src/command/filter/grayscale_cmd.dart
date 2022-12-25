import '../../filter/grayscale.dart' as g;
import '../command.dart';

class GrayscaleCmd extends Command {
  num amount;

  GrayscaleCmd(Command? input, { this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.grayscale(img, amount: amount) : null;
  }
}
