import 'dart:isolate';

import '../../filter/separable_convolution.dart';
import '../../filter/separable_kernel.dart';
import '../../image/image.dart';

class _SeparableConvolution {
  final SendPort port;
  final Image src;
  SeparableKernel kernel;
  _SeparableConvolution(this.port, this.src, this.kernel);
}

Future<Image> _separableConvolution(_SeparableConvolution p) async {
  final res = separableConvolution(p.src, p.kernel);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [separableConvolution].
Future<Image> separableConvolutionAsync(Image src,
    SeparableKernel kernel) async {
  final port = ReceivePort();
  await Isolate.spawn(_separableConvolution,
      _SeparableConvolution(port.sendPort, src, kernel));
  return await port.first as Image;
}
