import '../../filter/contrast.dart' as g;
import '../command.dart';

class ContrastCmd extends Command {
  final num _contrast;

  ContrastCmd(Command? input, { num contrast = 100.0 })
      : _contrast = contrast
      , super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.contrast(img, _contrast) : null;
  }
}
