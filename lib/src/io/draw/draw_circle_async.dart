import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_circle.dart';
import '../../image/image.dart';

class _DrawCircle {
  final SendPort port;
  final Image image;
  int x;
  int y;
  int radius;
  Color color;
  _DrawCircle(this.port, this.image, this.x, this.y, this.radius, this.color);
}

Future<void> _drawCircle(_DrawCircle p) async {
  drawCircle(p.image, p.x, p.y, p.radius, p.color);
  Isolate.exit(p.port);
}

/// Asynchronous call to [drawCircle].
Future<void> drawCircleAsync(Image image, int x, int y, int radius,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawCircle,
      _DrawCircle(port.sendPort, image, x, y, radius, color));
  return port.first;
}

Future<void> _fillCircle(_DrawCircle p) async {
  fillCircle(p.image, p.x, p.y, p.radius, p.color);
  Isolate.exit(p.port);
}

/// Asynchronous call to [fillCircle].
Future<void> fillCircleAsync(Image image, int x, int y, int radius,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_fillCircle,
      _DrawCircle(port.sendPort, image, x, y, radius, color));
  return port.first;
}

