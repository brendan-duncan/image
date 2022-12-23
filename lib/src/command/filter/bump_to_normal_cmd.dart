import '../../filter/bump_to_normal.dart' as g;
import '../command.dart';

class BumpToNormalCmd extends Command {
  num strength;

  BumpToNormalCmd(Command? input, { this.strength = 2.0 })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.bumpToNormal(img, strength: strength) : img;
  }
}
