import 'dart:isolate';

import '../../filter/bump_to_normal.dart';
import '../../image/image.dart';

class _BumpToNormal {
  final SendPort port;
  final Image src;
  final num strength;
  _BumpToNormal(this.port, this.src, this.strength);
}

Future<Image> _bumpToNormal(_BumpToNormal p) async {
  final res = bumpToNormal(p.src, strength: p.strength);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [bumpToNormal].
Future<Image> bumpToNormalAsync(Image src, { num strength = 2.0 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_bumpToNormal, _BumpToNormal(port.sendPort, src,
      strength));
  return await port.first as Image;
}
