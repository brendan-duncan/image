import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_rect.dart';
import '../../image/image.dart';

class _DrawRect {
  final SendPort port;
  final Image image;
  int x1;
  int y1;
  int x2;
  int y2;
  Color color;
  num thickness;
  _DrawRect(this.port, this.image, this.x1, this.y1, this.x2, this.y2,
      this.color, this.thickness);
}

Future<Image> _drawRect(_DrawRect p) async {
  final res = drawRect(p.image, p.x1, p.y1, p.x2, p.y2, p.color,
      thickness: p.thickness);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawRect].
Future<Image> drawRectAsync(Image image, int x1, int y1, int x2, int y2,
    Color color, { num thickness = 1 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawRect,
      _DrawRect(port.sendPort, image, x1, y1, x2, y2, color, thickness));
  return await port.first as Image;
}
