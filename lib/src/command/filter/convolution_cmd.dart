import '../../filter/convolution.dart' as g;
import '../command.dart';

class ConvolutionCmd extends Command {
  List<num> flt;
  num div;
  num offset;

  ConvolutionCmd(Command? input, this.flt, { this.div = 1.0,
      this.offset = 0 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.convolution(img, flt, div: div,
        offset: offset) : null;
  }
}
