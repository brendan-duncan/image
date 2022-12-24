import '../../filter/contrast.dart' as g;
import '../command.dart';

class ContrastCmd extends Command {
  num amount;

  ContrastCmd(Command? input, { this.amount = 100.0 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.contrast(img, amount) : null;
  }
}
