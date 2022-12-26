import '../../color/color.dart';
import '../../filter/monochrome.dart' as g;
import '../command.dart';

class MonochromeCmd extends Command {
  final num amount;
  final Color ?color;

  MonochromeCmd(Command? input, { this.color, this.amount = 1.0 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.monochrome(img, color: color, amount: amount)
        : null;
  }
}
