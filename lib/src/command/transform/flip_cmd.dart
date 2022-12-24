import '../../transform/flip.dart';
import '../command.dart';

class FlipCmd extends Command {
  FlipDirection direction;

  FlipCmd(Command? input, this.direction)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? flip(img, direction) : null;
  }
}
