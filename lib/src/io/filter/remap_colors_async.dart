import 'dart:isolate';

import '../../color/channel.dart';
import '../../filter/remap_colors.dart';
import '../../image/image.dart';

class _RemapColors {
  final SendPort port;
  final Image src;
  Channel red;
  Channel green;
  Channel blue;
  Channel alpha;
  _RemapColors(this.port, this.src, this.red, this.green, this.blue,
      this.alpha);
}

Future<Image> _remapColors(_RemapColors p) async {
  final res = remapColors(p.src, red: p.red, green: p.green, blue: p.blue,
      alpha: p.alpha);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [remapColors].
Future<Image> remapColorsAsync(Image src, { Channel red = Channel.red,
  Channel green = Channel.green,
  Channel blue = Channel.blue,
  Channel alpha = Channel.alpha }) async {
  final port = ReceivePort();
  await Isolate.spawn(_remapColors, _RemapColors(port.sendPort, src, red,
      green, blue, alpha));
  return await port.first as Image;
}
