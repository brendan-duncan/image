import '../../image/image.dart';
import '../command.dart';

typedef AddFramesCallback = Image? Function(int frameIndex);

class AddFramesCmd extends Command {
  int count;
  AddFramesCallback callback;
  AddFramesCmd(Command? input, this.count, this.callback)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;

    if (img != null) {
      for (var i = 0; i < count; ++i) {
        final frame = callback(i);
        if (frame != null) {
          img.addFrame(frame);
        }
      }
    }

    outputImage = img;
  }
}
