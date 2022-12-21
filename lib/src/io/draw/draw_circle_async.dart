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

Future<Image> _drawCircle(_DrawCircle p) async {
  final res = drawCircle(p.image, p.x, p.y, p.radius, p.color);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawCircle].
Future<Image> drawCircleAsync(Image image, int x, int y, int radius,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawCircle,
      _DrawCircle(port.sendPort, image, x, y, radius, color));
  return await port.first as Image;
}

Future<Image> _fillCircle(_DrawCircle p) async {
  final res = fillCircle(p.image, p.x, p.y, p.radius, p.color);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [fillCircle].
Future<Image> fillCircleAsync(Image image, int x, int y, int radius,
    Color color) async {
  final port = ReceivePort();
  await Isolate.spawn(_fillCircle,
      _DrawCircle(port.sendPort, image, x, y, radius, color));
  return await port.first as Image;
}

