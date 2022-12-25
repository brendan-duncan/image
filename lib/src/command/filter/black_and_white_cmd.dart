import '../../filter/black_and_white.dart';
import '../command.dart';

class BlackAndWhiteCmd extends Command {
  final num threshold;
  BlackAndWhiteCmd(Command? input, { this.threshold = 0.5 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? blackAndWhite(img, threshold: threshold) : null;
  }
}
