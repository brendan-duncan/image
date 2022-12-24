import '../../color/color.dart';
import '../../draw/fill_rect.dart';
import '../command.dart';

class FillRectCmd extends Command {
  int x1;
  int y1;
  int x2;
  int y2;
  Color c;

  FillRectCmd(Command? input, this.x1, this.y1, this.x2, this.y2, this.c)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? fillRect(img, x1, y1, x2, y2, c) : null;
  }
}
