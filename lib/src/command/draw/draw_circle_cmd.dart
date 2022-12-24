import '../../color/color.dart';
import '../../draw/draw_circle.dart';
import '../command.dart';

class DrawCircleCmd extends Command {
  int x;
  int y;
  int radius;
  Color color;

  DrawCircleCmd(Command? input, this.x, this.y, this.radius, this.color)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? drawCircle(img, x, y, radius, color) : null;
  }
}
