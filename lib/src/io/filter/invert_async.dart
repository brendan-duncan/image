import 'dart:isolate';

import '../../filter/invert.dart';
import '../../image/image.dart';

class _Invert {
  final SendPort port;
  final Image src;
  _Invert(this.port, this.src);
}

Future<Image> _invert(_Invert p) async {
  final res = invert(p.src);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [invert].
Future<Image> invertAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_invert, _Invert(port.sendPort, src));
  return await port.first as Image;
}
