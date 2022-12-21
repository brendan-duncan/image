import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/fill.dart';
import '../../image/image.dart';

class _Fill {
  final SendPort port;
  final Image image;
  final Color color;
  _Fill(this.port, this.image, this.color);
}

Future<Image> _fill(_Fill p) async {
  final res = fill(p.image, p.color);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [fill].
Future<Image> fillAsync(Image image, int x, int y, int radius,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_fill, _Fill(port.sendPort, image, color));
  return await port.first as Image;
}
