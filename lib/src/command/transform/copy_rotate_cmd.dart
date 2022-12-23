import '../../transform/copy_rotate.dart';
import '../../util/interpolation.dart';
import '../command.dart';

class CopyRotateCmd extends Command {
  num angle;
  Interpolation interpolation;

  CopyRotateCmd(Command? input, this.angle,
      { this.interpolation = Interpolation.nearest })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ?
        copyRotate(img, angle, interpolation: interpolation) : null;
  }
}
