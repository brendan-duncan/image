import '../../color/color.dart';
import '../../draw/draw_pixel.dart';
import '../command.dart';

class DrawPixelCmd extends Command {
  int x;
  int y;
  Color color;
  double? overrideAlpha;

  DrawPixelCmd(Command? input, this.x, this.y, this.color, [this.overrideAlpha])
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? drawPixel(img, x, y, color, overrideAlpha)
        : null;
  }
}
