import 'dart:isolate';

import '../../filter/vignette.dart';
import '../../image/image.dart';

class _Vignette {
  final SendPort port;
  final Image src;
  final num start;
  final num end;
  final num amount;
  _Vignette(this.port, this.src, this.start, this.end, this.amount);
}

Future<Image> _vignette(_Vignette p) async {
  final res = vignette(p.src, start: p.start, end: p.end, amount: p.amount);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [vignette].
Future<Image> vignetteAsync(Image src, { num start = 0.3, num end = 0.75,
    num amount = 0.8 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_vignette, _Vignette(port.sendPort, src, start, end,
      amount));
  return await port.first as Image;
}
