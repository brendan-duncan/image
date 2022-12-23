import '../../transform/flip.dart';
import '../command.dart';

class FlipCmd extends Command {
  FlipDirection direction;

  FlipCmd(Command? input, this.direction)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? flip(img, direction) : null;
  }
}
