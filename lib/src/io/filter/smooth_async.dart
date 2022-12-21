import 'dart:isolate';

import '../../filter/smooth.dart';
import '../../image/image.dart';

class _Smooth {
  final SendPort port;
  final Image src;
  final num w;
  _Smooth(this.port, this.src, this.w);
}

Future<Image> _smooth(_Smooth p) async {
  final res = smooth(p.src, p.w);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [smooth].
Future<Image> smoothAsync(Image src, num w) async {
  final port = ReceivePort();
  await Isolate.spawn(_smooth, _Smooth(port.sendPort, src, w));
  return await port.first as Image;
}
