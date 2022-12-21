import 'dart:isolate';

import '../../color/color.dart';
import '../../filter/scale_rgba.dart';
import '../../image/image.dart';

class _ScaleRgba {
  final SendPort port;
  final Image src;
  Color s;
  _ScaleRgba(this.port, this.src, this.s);
}

Future<Image> _scaleRgba(_ScaleRgba p) async {
  final res = scaleRgba(p.src, p.s);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [scaleRgba].
Future<Image> scaleRgbaAsync(Image src, Color s) async {
  final port = ReceivePort();
  await Isolate.spawn(_scaleRgba, _ScaleRgba(port.sendPort, src, s));
  return await port.first as Image;
}
