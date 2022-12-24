import '../../color/color.dart';
import '../../draw/draw_char.dart';
import '../../font/bitmap_font.dart';
import '../command.dart';

class DrawCharCmd extends Command {
  BitmapFont font;
  int x;
  int y;
  String char;
  Color? color;

  DrawCharCmd(Command? input, this.font, this.x, this.y, this.char,
      { this.color })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? drawChar(img, font, x, y, char, color: color)
        : null;
  }
}
