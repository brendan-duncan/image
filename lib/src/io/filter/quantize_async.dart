import 'dart:isolate';

import '../../filter/dither_image.dart';
import '../../filter/quantize.dart';
import '../../image/image.dart';

class _Quantize {
  final SendPort port;
  final Image src;
  int numberOfColors = 256;
  QuantizeMethod method = QuantizeMethod.neuralNet;
  DitherKernel dither;
  bool ditherSerpentine;
  _Quantize(this.port, this.src, this.numberOfColors, this.method,
      this.dither, this.ditherSerpentine);
}

Future<Image> _quantize(_Quantize p) async {
  final res = quantize(p.src, numberOfColors: p.numberOfColors,
      method: p.method, dither: p.dither, ditherSerpentine: p.ditherSerpentine);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [quantize].
Future<Image> quantizeAsync(Image src, { int numberOfColors = 256,
  QuantizeMethod method = QuantizeMethod.neuralNet,
  DitherKernel dither = DitherKernel.none,
  bool ditherSerpentine = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_quantize, _Quantize(port.sendPort, src, numberOfColors,
      method, dither, ditherSerpentine));
  return await port.first as Image;
}
