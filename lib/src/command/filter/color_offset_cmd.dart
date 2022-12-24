import '../../filter/color_offset.dart' as g;
import '../command.dart';

class ColorOffsetCmd extends Command {
  num red;
  num green;
  num blue;
  num alpha;

  ColorOffsetCmd(Command? input, { this.red = 0, this.green = 0, this.blue = 0,
      this.alpha = 0})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.colorOffset(img, red: red, green: green,
        blue: blue, alpha: alpha) : null;
  }
}
