import 'dart:isolate';

import '../../filter/contrast.dart';
import '../../image/image.dart';

class _Contrast {
  final SendPort port;
  final Image src;
  final num contrast;
  _Contrast(this.port, this.src, this.contrast);
}

Future<Image> _contrast(_Contrast p) async {
  final res = contrast(p.src, p.contrast);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [contrast].
Future<Image> contrastAsync(Image src, num c) async {
  final port = ReceivePort();
  await Isolate.spawn(_contrast, _Contrast(port.sendPort, src, c));
  return await port.first as Image;
}
