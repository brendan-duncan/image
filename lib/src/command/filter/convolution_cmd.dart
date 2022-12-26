import '../../filter/convolution.dart' as g;
import '../command.dart';

class ConvolutionCmd extends Command {
  List<num> flt;
  num div;
  num offset;
  num amount;

  ConvolutionCmd(Command? input, this.flt, { this.div = 1.0,
      this.offset = 0, this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.convolution(img, flt, div: div,
        offset: offset, amount: amount) : null;
  }
}
