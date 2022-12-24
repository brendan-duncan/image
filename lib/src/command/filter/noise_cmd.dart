import 'dart:math';

import '../../filter/noise.dart' as g;
import '../command.dart';

class NoiseCmd extends Command {
  num sigma;
  g.NoiseType type;
  Random? random;

  NoiseCmd(Command? input, this.sigma,
      { this.type = g.NoiseType.gaussian, this.random })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.noise(img, sigma, type: type, random: random)
        : null;
  }
}
