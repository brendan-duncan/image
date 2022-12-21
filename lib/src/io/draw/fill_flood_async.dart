import 'dart:isolate';
import 'dart:typed_data';

import '../../color/color.dart';
import '../../draw/fill_flood.dart';
import '../../image/image.dart';

class _FillFlood {
  final SendPort port;
  final Image image;
  final int x;
  final int y;
  final Color? color;
  final num threshold;
  final bool compareAlpha;
  final int fillValue;
  _FillFlood(this.port, this.image, this.x, this.y, this.color, this.threshold,
      this.compareAlpha, this.fillValue);
}

Future<Image> _fillFlood(_FillFlood p) async {
  final res = fillFlood(p.image, p.x, p.y, p.color!, threshold: p.threshold,
      compareAlpha: p.compareAlpha);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [fillFlood].
Future<Image> fillFloodAsync(Image image, int x, int y, Color color,
    {num threshold = 0.0, bool compareAlpha = false}) async {
  final port = ReceivePort();
  await Isolate.spawn(_fillFlood, _FillFlood(port.sendPort, image, x, y, color,
      threshold, compareAlpha, 255));
  return await port.first as Image;
}

Future<Uint8List> _maskFlood(_FillFlood p) async {
  final res = maskFlood(p.image, p.x, p.y, threshold: p.threshold,
      compareAlpha: p.compareAlpha, fillValue: p.fillValue);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [maskFlood].
Future<Uint8List> maskFloodAsync(Image image, int x, int y,
    { num threshold = 0.0, bool compareAlpha = false,
      int fillValue = 255 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_maskFlood, _FillFlood(port.sendPort, image, x, y, null,
      threshold, compareAlpha, fillValue));
  return await port.first as Uint8List;
}
