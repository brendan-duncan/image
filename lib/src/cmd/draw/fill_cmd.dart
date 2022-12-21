import '../../color/color.dart';
import '../../draw/fill.dart';
import '../image_command.dart';

class FillCmd extends ImageCommand {
  ImageCommand? input;
  Color color;

  FillCmd(this.input, this.color);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? fill(img, color) : img;
  }
}
