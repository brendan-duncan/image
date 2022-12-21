import 'dart:isolate';

import '../../filter/normalize.dart';
import '../../image/image.dart';

class _Normalize {
  final SendPort port;
  final Image src;
  num minValue;
  num maxValue;
  _Normalize(this.port, this.src, this.minValue, this.maxValue);
}

Future<Image> _normalize(_Normalize p) async {
  final res = normalize(p.src, p.minValue, p.maxValue);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [normalize].
Future<Image> normalizeAsync(Image src, num minValue, num maxValue) async {
  final port = ReceivePort();
  await Isolate.spawn(_normalize, _Normalize(port.sendPort, src, minValue,
      maxValue));
  return await port.first as Image;
}
