import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_line.dart';
import '../../image/image.dart';

class _DrawLine {
  final SendPort port;
  final Image image;
  int x1;
  int y1;
  int x2;
  int y2;
  Color color;
  num thickness;
  bool antialias;
  _DrawLine(this.port, this.image, this.x1, this.y1, this.x2, this.y2,
      this.color, this.thickness, this.antialias);
}

Future<Image> _drawLine(_DrawLine p) async {
  final res = drawLine(p.image, p.x1, p.y1, p.x2, p.y2, p.color,
      thickness: p.thickness, antialias: p.antialias);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawLine].
Future<Image> drawLineAsync(Image image, int x1, int y1, int x2, int y2,
    Color color, { num thickness = 1, bool antialias = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawLine,
      _DrawLine(port.sendPort, image, x1, y1, x2, y2, color, thickness,
          antialias));
  return await port.first as Image;
}
