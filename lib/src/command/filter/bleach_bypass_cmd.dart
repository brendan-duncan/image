import '../../filter/bleach_bypass.dart';
import '../command.dart';

class BleachBypassCmd extends Command {
  num amount;
  BleachBypassCmd(Command? input, { this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? bleachBypass(img, amount: amount) : null;
  }
}
