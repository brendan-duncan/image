import '../../filter/dither_image.dart' as g;
import '../../util/quantizer.dart';
import '../command.dart';

class DitherImageCmd extends Command {
  final Quantizer? quantizer;
  final g.DitherKernel kernel;

  /// Use [scanOrder] instead.
  final bool serpentine;

  final g.DitherScanOrder? scanOrder;

  final double strength;

  DitherImageCmd(
    Command? input, {
    this.quantizer,
    this.kernel = g.DitherKernel.floydSteinberg,
    this.serpentine = false,
    this.scanOrder,
    this.strength = 1.0,
  }) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    // Match ditherImage: the deprecated serpentine flag takes precedence,
    // and the default scan order is zigzag.
    final order = serpentine
        ? g.DitherScanOrder.serpentine
        : (scanOrder ?? g.DitherScanOrder.zigzag);
    outputImage = img != null
        ? g.ditherImage(img,
            quantizer: quantizer,
            kernel: kernel,
            scanOrder: order,
            strength: strength)
        : null;
  }
}
