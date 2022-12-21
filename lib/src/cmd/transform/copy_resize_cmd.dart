import '../../transform/copy_resize.dart';
import '../../util/interpolation.dart';
import '../image_command.dart';

class CopyResizeCmd extends ImageCommand {
  ImageCommand? input;
  int? width;
  int? height;
  Interpolation interpolation;

  CopyResizeCmd(this.input, { this.width, this.height,
      this.interpolation = Interpolation.nearest });

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? copyResize(img, width: width, height: height,
        interpolation: interpolation) : img;
  }
}
