import '../../filter/normalize.dart' as g;
import '../command.dart';

class NormalizeCmd extends Command {
  num minValue;
  num maxValue;

  NormalizeCmd(Command? input, this.minValue, this.maxValue)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.normalize(img, minValue, maxValue) : null;
  }
}
