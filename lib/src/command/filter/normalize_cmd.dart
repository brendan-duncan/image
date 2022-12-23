import '../../filter/normalize.dart' as g;
import '../command.dart';

class NormalizeCmd extends Command {
  num minValue;
  num maxValue;

  NormalizeCmd(Command? input, this.minValue, this.maxValue)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.normalize(img, minValue, maxValue) : img;
  }
}
