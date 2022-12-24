import '../../transform/copy_rectify.dart';
import '../../util/point.dart';
import '../command.dart';

class CopyRectifyCmd extends Command {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;

  CopyRectifyCmd(Command? input, this.topLeft, this.topRight,
      this.bottomLeft, this.bottomRight)
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
