import '../../color/color.dart';
import '../../filter/scale_rgba.dart' as g;
import '../command.dart';

class ScaleRgbaCmd extends Command {
  Color s;

  ScaleRgbaCmd(Command? input, this.s)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.scaleRgba(img, s) : null;
  }
}
