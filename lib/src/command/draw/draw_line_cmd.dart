import '../../color/color.dart';
import '../../draw/draw_line.dart';
import '../command.dart';

class DrawLineCmd extends Command {
  int x1;
  int y1;
  int x2;
  int y2;
  Color c;
  bool antialias;
  num thickness;

  DrawLineCmd(Command? input, this.x1, this.y1, this.x2, this.y2, this.c,
      { this.antialias = false, this.thickness = 1 })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? drawLine(img, x1, y1, x2, y2, c, antialias: antialias,
        thickness: thickness) : img;
  }
}
