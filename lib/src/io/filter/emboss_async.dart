import 'dart:isolate';

import '../../filter/emboss.dart';
import '../../image/image.dart';

class _Emboss {
  final SendPort port;
  final Image src;
  _Emboss(this.port, this.src);
}

Future<Image> _emboss(_Emboss p) async {
  final res = emboss(p.src);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [emboss].
Future<Image> embossAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_emboss, _Emboss(port.sendPort, src));
  return await port.first as Image;
}
