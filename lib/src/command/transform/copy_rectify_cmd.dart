import '../../image/interpolation.dart';
import '../../transform/copy_rectify.dart';
import '../../util/point.dart';
import '../command.dart';

class CopyRectifyCmd extends Command {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;
  Interpolation interpolation;

  CopyRectifyCmd(Command? input, this.topLeft, this.topRight,
      this.bottomLeft, this.bottomRight, this.interpolation)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? copyRectify(img, topLeft: topLeft,
        topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
        : null;
  }
}
