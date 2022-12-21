import 'dart:isolate';

import '../../filter/sobel.dart';
import '../../image/image.dart';

class _Sobel {
  final SendPort port;
  final Image src;
  final num amount;
  _Sobel(this.port, this.src, this.amount);
}

Future<Image> _sobel(_Sobel p) async {
  final res = sobel(p.src, amount: p.amount);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [sobel].
Future<Image> sobelAsync(Image src, num c) async {
  final port = ReceivePort();
  await Isolate.spawn(_sobel, _Sobel(port.sendPort, src, c));
  return await port.first as Image;
}
