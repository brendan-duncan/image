import '../../filter/dot_screen.dart' as g;
import '../command.dart';

class DotScreenCmd extends Command {
  final num angle;
  final num size;
  final int? centerX;
  final int? centerY;
  final num amount;
  DotScreenCmd(Command? input, { this.angle = 180, this.size = 5.75,
      this.centerX, this.centerY, this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.dotScreen(img, angle: angle, size: size,
        centerX: centerX, centerY: centerY, amount: amount) : null;
  }
}
