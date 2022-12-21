import 'dart:isolate';

import '../../filter/color_offset.dart';
import '../../image/image.dart';

class _ColorOffset {
  final SendPort port;
  final Image src;
  final num red;
  final num green;
  final num blue;
  final num alpha;
  _ColorOffset(this.port, this.src, this.red, this.green, this.blue,
      this.alpha);
}

Future<Image> _colorOffset(_ColorOffset p) async {
  final res = colorOffset(p.src, red: p.red, green: p.green,
      blue: p.blue, alpha: p.alpha);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [colorOffset].
Future<Image> colorOffsetAsync(Image src,
    { num red = 0, num green = 0, num blue = 0, num alpha = 0 }) async {
  final port = ReceivePort();
  await Isolate.spawn(_colorOffset, _ColorOffset(port.sendPort, src,
      red, green, blue, alpha));
  return await port.first as Image;
}
