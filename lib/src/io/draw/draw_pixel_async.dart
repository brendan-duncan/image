import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_pixel.dart';
import '../../image/image.dart';

class _DrawPixel {
  final SendPort port;
  final Image image;
  int x;
  int y;
  Color color;
  double? overrideAlpha;
  _DrawPixel(this.port, this.image, this.x, this.y, this.color,
      this.overrideAlpha);
}

Future<Image> _drawPixel(_DrawPixel p) async {
  final res = drawPixel(p.image, p.x, p.y, p.color, p.overrideAlpha);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawPixel].
Future<Image> drawPixelAsync(Image image, int x, int y, Color color,
    [double? overrideAlpha]) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawPixel,
      _DrawPixel(port.sendPort, image, x, y, color, overrideAlpha));
  return await port.first as Image;
}
