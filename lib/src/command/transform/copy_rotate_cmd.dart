import '../../image/interpolation.dart';
import '../../transform/copy_rotate.dart';
import '../command.dart';

class CopyRotateCmd extends Command {
  num angle;
  Interpolation interpolation;
  bool linearBlend;

  CopyRotateCmd(Command? input,
      {required this.angle,
      this.interpolation = Interpolation.nearest,
      this.linearBlend = false})
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyRotate(img,
            angle: angle,
            interpolation: interpolation,
            linearBlend: linearBlend)
        : null;
  }
}
