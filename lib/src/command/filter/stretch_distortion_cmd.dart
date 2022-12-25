import '../../filter/stretch_distortion.dart';
import '../../util/interpolation.dart';
import '../command.dart';

class StretchDistortionCmd extends Command {
  int? centerX;
  int? centerY;
  Interpolation interpolation;
  StretchDistortionCmd(Command? input, { this.centerX, this.centerY,
  this.interpolation = Interpolation.nearest})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? stretchDistortion(img, centerX: centerX,
        centerY: centerY, interpolation: interpolation) : null;
  }
}
