import '../../color/color.dart';
import '../../draw/draw_rect.dart';
import '../command.dart';

class DrawRectCmd extends Command {
  int x1;
  int y1;
  int x2;
  int y2;
  Color c;
  num thickness;

  DrawRectCmd(Command? input, this.x1, this.y1, this.x2, this.y2, this.c,
      { this.thickness = 1 })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? drawRect(img, x1, y1, x2, y2, c,
        thickness: thickness) : null;
  }
}
