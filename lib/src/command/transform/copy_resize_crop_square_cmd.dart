import '../../transform/copy_resize_crop_square.dart';
import '../command.dart';

class CopyResizeCropSquareCmd extends Command {
  int size;

  CopyResizeCropSquareCmd(Command? input, this.size)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? copyResizeCropSquare(img, size) : img;
  }
}
