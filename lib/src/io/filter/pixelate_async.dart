import 'dart:isolate';

import '../../filter/pixelate.dart';
import '../../image/image.dart';

class _Pixelate {
  final SendPort port;
  final Image src;
  int blockSize;
  PixelateMode mode;
  _Pixelate(this.port, this.src, this.blockSize, this.mode);
}

Future<Image> _pixelate(_Pixelate p) async {
  final res = pixelate(p.src, p.blockSize, mode: p.mode);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [pixelate].
Future<Image> pixelateAsync(Image src, int blockSize,
    { PixelateMode mode = PixelateMode.upperLeft }) async {
  final port = ReceivePort();
  await Isolate.spawn(_pixelate, _Pixelate(port.sendPort, src, blockSize,
      mode));
  return await port.first as Image;
}
