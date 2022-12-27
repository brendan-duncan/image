import '../../filter/reinhard_tone_map.dart' as g;
import '../command.dart';

class ReinhardTonemapCmd extends Command {
  ReinhardTonemapCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.reinhardTonemap(img) : null;
  }
}
