import '../../transform/copy_crop_circle.dart';
import '../command.dart';

class CopyCropCircleCmd extends Command {
  int? radius;
  int? centerX;
  int? centerY;

  CopyCropCircleCmd(Command? input, { this.radius, this.centerX, this.centerY })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ?
        copyCropCircle(img, radius: radius, centerX: centerX, centerY: centerY)
        : null;
  }
}
