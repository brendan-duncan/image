import '../../filter/bleach_bypass.dart';
import '../command.dart';

class BleachBypassCmd extends Command {
  BleachBypassCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? bleachBypass(img) : null;
  }
}
