import 'dart:isolate';

import '../../filter/sepia.dart';
import '../../image/image.dart';

class _Sepia {
  final SendPort port;
  final Image src;
  final num amount;
  _Sepia(this.port, this.src, this.amount);
}

Future<Image> _sepia(_Sepia p) async {
  final res = sepia(p.src, amount: p.amount);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [sepia].
Future<Image> sepiaAsync(Image src, num c) async {
  final port = ReceivePort();
  await Isolate.spawn(_sepia, _Sepia(port.sendPort, src, c));
  return await port.first as Image;
}
