import '../../filter/vignette.dart' as g;
import '../command.dart';

class VignetteCmd extends Command {
  num start;
  num end;
  num amount;

  VignetteCmd(Command? input, { this.start = 0.3, this.end = 0.75,
      this.amount = 0.8 })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.vignette(img, start: start, end: end,
        amount: amount) : null;
  }
}

