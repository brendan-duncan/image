import '../../color/color.dart';
import '../../image/image.dart';
import '../../transform/copy_expand_canvas.dart';
import '../command.dart';

class CopyExpandCanvasCmd extends Command {
  int? newWidth;
  int? newHeight;
  int? padding;
  ExpandCanvasPosition position;
  Color? backgroundColor;
  Image? toImage;

  CopyExpandCanvasCmd(
    Command? input, {
    this.newWidth,
    this.newHeight,
    this.padding,
    this.position = ExpandCanvasPosition.center,
    this.backgroundColor,
    this.toImage,
  }) : super(input) {
    if ((newWidth == null || newHeight == null) && padding == null) {
      throw ArgumentError('Either new dimensions or padding must be provided');
    }
    if (newWidth != null && newHeight != null && padding != null) {
      throw ArgumentError('Cannot provide both new dimensions and padding');
    }
  }

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;

    int effectiveNewWidth, effectiveNewHeight;

    if (padding != null) {
      assert(img != null);
      effectiveNewWidth = img!.width + padding! * 2;
      effectiveNewHeight = img.height + padding! * 2;
    } else {
      effectiveNewWidth = newWidth!;
      effectiveNewHeight = newHeight!;
    }

    outputImage = img != null
        ? copyExpandCanvas(
            img,
            newWidth: effectiveNewWidth,
            newHeight: effectiveNewHeight,
            position: position,
            backgroundColor: backgroundColor,
            toImage: toImage,
          )
        : null;
  }
}
