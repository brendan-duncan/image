import '../../color/color.dart';
import '../../image/interpolation.dart';
import '../../transform/copy_resize.dart';
import '../command.dart';

class CopyResizeCmd extends Command {
  int? width;
  int? height;
  bool? maintainAspect;
  Color? backgroundColor;
  Interpolation interpolation;

  CopyResizeCmd(Command? input,
      {this.width,
      this.height,
      this.maintainAspect,
      this.backgroundColor,
      this.interpolation = Interpolation.nearest})
      : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    outputImage = img != null
        ? copyResize(img,
            width: width,
            height: height,
            maintainAspect: maintainAspect,
            backgroundColor: backgroundColor,
            interpolation: interpolation)
        : null;
  }
}
