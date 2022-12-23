import '../../transform/copy_flip.dart';
import '../../transform/flip.dart';
import '../command.dart';

class CopyFlipCmd extends Command {
  FlipDirection direction;

  CopyFlipCmd(Command? input, this.direction)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? copyFlip(img, direction) : null;
  }
}
