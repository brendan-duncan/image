import '../command.dart';
import 'image_cmd.dart';

class ForEachFrameCmd extends Command {
  final Command toExecute;

  ForEachFrameCmd(Command? input, this.toExecute)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    if (img == null) {
      return;
    }

    image = input?.image;
    bytes = input?.bytes;

    final subCmd = toExecute.firstSubCommand ?? toExecute;
    final imgCmd = ImageCmd(img)
      ..subCommand = subCmd;

    final savedInput = subCmd.input;
    subCmd.input = imgCmd;

    for (var frame in img.frames) {
      currentFrameStack.add(frame);
      imgCmd..setDirty()
      ..image = frame
      ..execute();
      currentFrameStack.removeLast();
    }

    subCmd.input = savedInput;
  }
}
