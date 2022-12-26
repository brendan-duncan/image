import '../../filter/edge_glow.dart' as g;
import '../command.dart';

class EdgeGlowCmd extends Command {
  num amount;

  EdgeGlowCmd(Command? input, { this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.edgeGlow(img, amount: amount) : null;
  }
}
