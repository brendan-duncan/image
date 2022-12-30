import '../../image/interpolation.dart';
import '../../transform/copy_resize_crop_square.dart';
import '../command.dart';

class CopyResizeCropSquareCmd extends Command {
  int size;
  Interpolation interpolation;

  CopyResizeCropSquareCmd(Command? input, { required this.size,
      this.interpolation = Interpolation.nearest })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? copyResizeCropSquare(img, size: size,
        interpolation: interpolation) : null;
  }
}
