import 'dart:isolate';

import '../../filter/gamma.dart';
import '../../image/image.dart';

class _Gamma {
  final SendPort port;
  final Image src;
  final num gamma;
  _Gamma(this.port, this.src, this.gamma);
}

Future<Image> _gamma(_Gamma p) async {
  final res = gamma(p.src, gamma: p.gamma);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [gamma].
Future<Image> gammaAsync(Image src, num g) async {
  final port = ReceivePort();
  await Isolate.spawn(_gamma, _Gamma(port.sendPort, src, g));
  return await port.first as Image;
}
