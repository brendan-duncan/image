import '../../color/color.dart';
import '../../draw/draw_string.dart';
import '../../font/bitmap_font.dart';
import '../command.dart';

class DrawStringCmd extends Command {
  BitmapFont font;
  int x;
  int y;
  String char;
  Color? color;

  DrawStringCmd(Command? input, this.font, this.x, this.y, this.char,
      { this.color })
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? drawString(img, font, x, y, char, color: color) : img;
  }
}
