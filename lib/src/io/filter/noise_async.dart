import 'dart:isolate';
import 'dart:math';

import '../../filter/noise.dart';
import '../../image/image.dart';

class _Noise {
  final SendPort port;
  final Image src;
  num sigma;
  NoiseType type;
  Random? random;
  _Noise(this.port, this.src, this.sigma, this.type, this.random);
}

Future<Image> _noise(_Noise p) async {
  final res = noise(p.src, p.sigma, type: p.type, random: p.random);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [noise].
Future<Image> noiseAsync(Image src, num sigma,
    { NoiseType type = NoiseType.gaussian, Random? random }) async {
  final port = ReceivePort();
  await Isolate.spawn(_noise, _Noise(port.sendPort, src, sigma, type, random));
  return await port.first as Image;
}
