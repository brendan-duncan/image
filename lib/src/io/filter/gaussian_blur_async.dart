import 'dart:isolate';

import '../../filter/gaussian_blur.dart';
import '../../image/image.dart';

class _GaussianBlur {
  final SendPort port;
  final Image src;
  final int radius;
  _GaussianBlur(this.port, this.src, this.radius);
}

Future<Image> _gaussianBlur(_GaussianBlur p) async {
  final res = gaussianBlur(p.src, p.radius);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [gaussianBlur].
Future<Image> gaussianBlurAsync(Image src, int radius) async {
  final port = ReceivePort();
  await Isolate.spawn(_gaussianBlur, _GaussianBlur(port.sendPort, src, radius));
  return await port.first as Image;
}
