import '../../filter/emboss.dart' as g;
import '../command.dart';

class EmbossCmd extends Command {
  num amount;

  EmbossCmd(Command? input, { this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.emboss(img, amount: amount) : null;
  }
}
