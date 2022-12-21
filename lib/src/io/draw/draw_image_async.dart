import 'dart:isolate';

import '../../draw/draw_image.dart';
import '../../image/image.dart';

class _DrawImage {
  final SendPort port;
  Image dst;
  Image src;
  int? dstX;
  int? dstY;
  int? dstW;
  int? dstH;
  int? srcX;
  int? srcY;
  int? srcW;
  int? srcH;
  bool blend;
  bool center;
  _DrawImage(this.port, this.dst, this.src, this.dstX, this.dstY,
      this.dstW, this.dstH, this.srcX, this.srcY, this.srcW, this.srcH,
      this.blend, this.center);
}

Future<Image> _drawImage(_DrawImage p) async {
  final res = drawImage(p.dst, p.src, dstX: p.dstX, dstY: p.dstY, dstW: p.dstW,
      dstH: p.dstH, srcX: p.srcX, srcY: p.srcY, srcW: p.srcW, srcH: p.srcH,
      blend: p.blend, center: p.center);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawImage].
Future<Image> drawImageAsync(Image dst, Image src, {
    int? dstX,
    int? dstY,
    int? dstW,
    int? dstH,
    int? srcX,
    int? srcY,
    int? srcW,
    int? srcH,
    bool blend = true,
    bool center = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawImage,
      _DrawImage(port.sendPort, dst, src, dstX, dstY, dstW,
          dstH, srcX, srcY, srcW, srcH,
          blend, center));
  return await port.first as Image;
}
