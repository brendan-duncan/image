import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_rotate.dart';
import '../../util/interpolation.dart';

class _CopyRotate {
  final SendPort port;
  Image image;
  num angle;
  Interpolation interpolation;
  _CopyRotate(this.port, this.image, this.angle, this.interpolation);
}

Future<void> _copyRotate(_CopyRotate p) async {
  final res = copyRotate(p.image, p.angle, interpolation: p.interpolation);
  Isolate.exit(p.port, res);
}

/// Returns a copy of the [src] image, rotated by [angle] degrees.
Future<Image> copyRotateAsync(Image src, num angle,
    {Interpolation interpolation = Interpolation.nearest}) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyRotate,
      _CopyRotate(port.sendPort, src, angle, interpolation));
  return await port.first as Image;
}
