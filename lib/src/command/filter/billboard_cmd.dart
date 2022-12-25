import '../../filter/billboard.dart';
import '../command.dart';

class BillboardCmd extends Command {
  final num grid;
  final num amount;
  BillboardCmd(Command? input, { this.grid = 10, this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? billboard(img, grid: grid, amount: amount)
        : null;
  }
}
