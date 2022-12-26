import '../../filter/hexagon_pixelate.dart' as g;
import '../command.dart';

class HexagonPixelateCmd extends Command {
  int? centerX;
  int? centerY;
  int size;
  num amount;

  HexagonPixelateCmd(Command? input, { this.centerX, this.centerY,
      this.size = 5, this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.hexagonPixelate(img, centerX: centerX,
        centerY: centerY, size: size, amount: amount) : null;
  }
}
