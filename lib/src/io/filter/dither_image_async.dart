import 'dart:isolate';

import '../../filter/dither_image.dart';
import '../../image/image.dart';
import '../../util/quantizer.dart';

class _DitherImage {
  final SendPort port;
  final Image src;
  Quantizer? quantizer;
  DitherKernel kernel;
  bool serpentine;
  _DitherImage(this.port, this.src, this.quantizer, this.kernel,
      this.serpentine);
}

Future<Image> _ditherImage(_DitherImage p) async {
  final res = ditherImage(p.src, quantizer: p.quantizer, kernel: p.kernel,
      serpentine: p.serpentine);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [ditherImage].
Future<Image> ditherImageAsync(Image src, { Quantizer? quantizer,
    DitherKernel kernel = DitherKernel.floydSteinberg,
    bool serpentine = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_ditherImage, _DitherImage(port.sendPort, src, quantizer,
      kernel, serpentine));
  return await port.first as Image;
}
