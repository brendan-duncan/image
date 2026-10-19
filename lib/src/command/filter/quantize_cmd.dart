import '../../filter/dither_image.dart' as d;
import '../../filter/quantize.dart' as g;
import '../command.dart';

class QuantizeCmd extends Command {
  int numberOfColors;
  g.QuantizeMethod method;
  d.DitherKernel dither;

  /// Use [ditherScanOrder] instead.
  bool ditherSerpentine;

  d.DitherScanOrder? ditherScanOrder;

  double ditherStrength;

  QuantizeCmd(
    Command? input, {
    this.numberOfColors = 256,
    this.method = g.QuantizeMethod.neuralNet,
    this.dither = d.DitherKernel.none,
    this.ditherSerpentine = false,
    this.ditherScanOrder,
    this.ditherStrength = 1.0,
  }) : super(input);

  @override
  Future<void> executeCommand() async {
    final img = await input?.getImage();
    final order = ditherScanOrder ??
        (ditherSerpentine
            ? d.DitherScanOrder.serpentine
            : d.DitherScanOrder.raster);
    outputImage = img != null
        ? g.quantize(
            img,
            numberOfColors: numberOfColors,
            method: method,
            dither: dither,
            ditherScanOrder: order,
            ditherStrength: ditherStrength,
          )
        : null;
  }
}
