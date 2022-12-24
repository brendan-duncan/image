import '../../transform/copy_flip.dart';
import '../../transform/flip.dart';
import '../command.dart';

class CopyFlipCmd extends Command {
  FlipDirection direction;

  CopyFlipCmd(Command? input, this.direction)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? copyFlip(img, direction) : null;
  }
}
