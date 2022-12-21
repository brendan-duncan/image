import 'dart:isolate';

import '../../filter/grayscale.dart';
import '../../image/image.dart';

class _Grayscale {
  final SendPort port;
  final Image src;
  _Grayscale(this.port, this.src);
}

Future<Image> _grayscale(_Grayscale p) async {
  final res = grayscale(p.src);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [grayscale].
Future<Image> grayscaleAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_grayscale, _Grayscale(port.sendPort, src));
  return await port.first as Image;
}
