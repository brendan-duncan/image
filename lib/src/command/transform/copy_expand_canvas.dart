import '../../../image.dart';
import '../../transform/copy_expand_canvas.dart';

class CopyExpandCanvasCmd extends Command {
  int newWidth;
  int newHeight;
  ExpandCanvasPosition position;
  Color? backgroundColor;
  Image? toImage;

  CopyExpandCanvasCmd(
    Command? input, {
    required this.newWidth,
    required this.newHeight,
    this.position = ExpandCanvasPosition.center,
    this.backgroundColor,
    this.toImage,
  }) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null
        ? copyExpandCanvas(
            img,
            newWidth: newWidth,
            newHeight: newHeight,
            position: position,
            backgroundColor: backgroundColor,
            toImage: toImage,
          )
        : null;
  }
}
