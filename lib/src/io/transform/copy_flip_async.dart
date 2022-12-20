import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_flip.dart';
import '../../transform/flip.dart';

class _CopyFlip {
  final SendPort port;
  Image image;
  FlipDirection direction;
  _CopyFlip(this.port, this.image, this.direction);
}

Future<void> _copyFlip(_CopyFlip p) async {
  final res = copyFlip(p.image, p.direction);
  Isolate.exit(p.port, res);
}

/// Returns a copy of the [src] image, flipped by the given [direction].
Future<Image> copyFlipAsync(Image src, FlipDirection direction) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyFlip,
      _CopyFlip(port.sendPort, src, direction));
  return await port.first as Image;
}
