import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_crop.dart';

class _CopyCrop {
  final SendPort port;
  final Image image;
  final int x, y, w, h;
  _CopyCrop(this.port, this.image, this.x, this.y, this.w, this.h);
}

Future<void> _copyCrop(_CopyCrop p) async {
  final res = copyCrop(p.image, p.x, p.y, p.w, p.h);
  Isolate.exit(p.port, res);
}

/// Asynchronously crops a copy of [src].
Future<Image> copyCropAsync(Image src, int x, int y, int w, int h) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyCrop,
      _CopyCrop(port.sendPort, src, x, y, w, h));
  return await port.first as Image;
}

class _CopyCropCircle {
  final SendPort port;
  final Image image;
  final int? radius;
  final int? centerX;
  final int? centerY;
  _CopyCropCircle(this.port, this.image, this.radius, this.centerX,
      this.centerY);
}

Future<void> _copyCropCircle(_CopyCropCircle p) async {
  final res = copyCropCircle(p.image, radius: p.radius,
      centerX: p.centerX, centerY: p.centerY);
  Isolate.exit(p.port, res);
}

/// Asynchronously crops a copy of [src].
Future<Image> copyCropCircleAsync(Image src,
    {int? radius, int? centerX, int? centerY}) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyCropCircle,
      _CopyCropCircle(port.sendPort, src,radius, centerX, centerY));
  return await port.first as Image;
}
