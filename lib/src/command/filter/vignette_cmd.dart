import '../../color/color.dart';
import '../../filter/vignette.dart' as g;
import '../command.dart';

class VignetteCmd extends Command {
  num start;
  num end;
  num amount;
  Color? color;

  VignetteCmd(Command? input, { this.start = 0.3, this.end = 0.75,
      this.color, this.amount = 0.8 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.vignette(img, start: start, end: end,
        color: color, amount: amount) : null;
  }
}
