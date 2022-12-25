import '../../filter/bulge_distortion.dart';
import '../../util/interpolation.dart';
import '../command.dart';

class BulgeDistortionCmd extends Command {
  int? centerX;
  int? centerY;
  num? radius;
  num scale;
  Interpolation interpolation;
  BulgeDistortionCmd(Command? input, { this.centerX, this.centerY, this.radius,
      this.scale = 0.5, this.interpolation = Interpolation.nearest })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? bulgeDistortion(img, centerX: centerX,
        centerY: centerY, radius: radius, scale: scale,
        interpolation: interpolation) : null;
  }
}
