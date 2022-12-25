import '../../filter/sketch.dart' as g;
import '../command.dart';

class SketchCmd extends Command {
  num amount;

  SketchCmd(Command? input, { this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.sketch(img, amount: amount) : null;
  }
}
