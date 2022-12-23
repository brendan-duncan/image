import '../../transform/bake_orientation.dart';
import '../command.dart';

class BakeOrientationCmd extends Command {
  BakeOrientationCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? bakeOrientation(img) : null;
  }
}
