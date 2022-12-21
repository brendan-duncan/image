import 'dart:isolate';

import '../../color/color.dart';
import '../../filter/adjust_color.dart';
import '../../image/image.dart';

class _AdjustColor {
  final SendPort port;
  final Image src;
  Color? whites;
  Color? mids;
  num? contrast;
  num? saturation;
  num? brightness;
  num? gamma;
  num? exposure;
  num? hue;
  num? amount;
  _AdjustColor(this.port, this.src, this.whites, this.mids, this.contrast,
      this.saturation, this.brightness, this.gamma, this.exposure,
      this.hue, this.amount);
}

Future<Image> _adjustColor(_AdjustColor p) async {
  final res = adjustColor(p.src, whites: p.whites, mids: p.mids,
      contrast: p.contrast, saturation: p.saturation, brightness: p.brightness,
      gamma: p.gamma, exposure: p.exposure, hue: p.hue, amount: p.amount);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [adjustColor].
Future<Image> adjustColorAsync(Image src, { Color? blacks,
  Color? whites,
  Color? mids,
  num? contrast,
  num? saturation,
  num? brightness,
  num? gamma,
  num? exposure,
  num? hue,
  num? amount }) async {
  final port = ReceivePort();
  await Isolate.spawn(_adjustColor, _AdjustColor(port.sendPort, src, whites,
      mids, contrast, saturation, brightness, gamma, exposure, hue, amount));
  return await port.first as Image;
}
