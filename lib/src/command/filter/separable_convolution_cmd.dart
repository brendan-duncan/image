import '../../filter/separable_convolution.dart' as g;
import '../../filter/separable_kernel.dart' as g;
import '../command.dart';

class SeparableConvolutionCmd extends Command {
  g.SeparableKernel kernel;

  SeparableConvolutionCmd(Command? input, this.kernel)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    image = img != null ? g.separableConvolution(img, kernel) : img;
  }
}
