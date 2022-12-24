import '../../filter/gamma.dart' as g;
import '../command.dart';

class GammaCmd extends Command {
  final num _gamma;
  GammaCmd(Command? input, { num gamma = 2.2 })
      : _gamma = gamma
      , super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.gamma(img, gamma: _gamma) : null;
  }
}
