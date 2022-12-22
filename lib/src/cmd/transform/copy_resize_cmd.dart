import '../../transform/copy_resize.dart';
import '../../util/interpolation.dart';
import '../command.dart';

class CopyResizeCmd extends Command {
  int? width;
  int? height;
  Interpolation interpolation;

  CopyResizeCmd(Command? input, { this.width, this.height,
      this.interpolation = Interpolation.nearest })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? copyResize(img, width: width, height: height,
        interpolation: interpolation) : img;
  }
}
