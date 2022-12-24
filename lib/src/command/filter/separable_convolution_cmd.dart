import '../../filter/separable_convolution.dart' as g;
import '../../filter/separable_kernel.dart' as g;
import '../command.dart';

class SeparableConvolutionCmd extends Command {
  g.SeparableKernel kernel;

  SeparableConvolutionCmd(Command? input, this.kernel)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.separableConvolution(img, kernel) : null;
  }
}
