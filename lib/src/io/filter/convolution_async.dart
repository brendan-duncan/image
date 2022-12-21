import 'dart:isolate';

import '../../filter/convolution.dart';
import '../../image/image.dart';

class _Convolution {
  final SendPort port;
  final Image src;
  final List<num> filter;
  final num div;
  final num offset;
  _Convolution(this.port, this.src, this.filter, this.div, this.offset);
}

Future<Image> _convolution(_Convolution p) async {
  final res = convolution(p.src, p.filter, div: p.div, offset: p.offset);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [convolution].
Future<Image> convolutionAsync(Image src, List<num> filter,
    { num div = 1.0, num offset = 0.0 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_convolution, _Convolution(port.sendPort, src, filter,
      div, offset));
  return await port.first as Image;
}
