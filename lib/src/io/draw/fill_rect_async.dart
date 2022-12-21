import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/fill_rect.dart';
import '../../image/image.dart';

class _FillRect {
  final SendPort port;
  final Image image;
  int x1;
  int y1;
  int x2;
  int y2;
  Color color;
  _FillRect(this.port, this.image, this.x1, this.y1, this.x2, this.y2,
      this.color);
}

Future<void> _fillRect(_FillRect p) async {
  fillRect(p.image, p.x1, p.y1, p.x2, p.y2, p.color);
  Isolate.exit(p.port);
}

/// Asynchronous call to [fillRect].
Future<void> fillRectAsync(Image image, int x1, int y1, int x2, int y2,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_fillRect,
      _FillRect(port.sendPort, image, x1, y1, x2, y2, color));
  return port.first;
}
