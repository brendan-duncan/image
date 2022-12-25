import '../../filter/color_halftone.dart';
import '../command.dart';

class ColorHalftoneCmd extends Command {
  num amount;
  int? centerX;
  int? centerY;
  num angle = 180;
  num size = 5;

  ColorHalftoneCmd(Command? input, { this.amount = 1, this.centerX,
    this.centerY, this.angle = 180, this.size = 5 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? colorHalftone(img, amount: amount,
        centerX: centerX, centerY: centerY, angle: angle, size: size) : null;
  }
}
