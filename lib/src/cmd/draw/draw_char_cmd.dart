import '../../color/color.dart';
import '../../draw/draw_char.dart';
import '../../font/bitmap_font.dart';
import '../image_command.dart';

class DrawCharCmd extends ImageCommand {
  ImageCommand? input;
  BitmapFont font;
  int x;
  int y;
  String char;
  Color? color;

  DrawCharCmd(this.input, this.font, this.x, this.y, this.char,
      { this.color });

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? drawChar(img, font, x, y, char, color: color) : img;
  }
}
