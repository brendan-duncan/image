import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/flip.dart';

class _Flip {
  final SendPort port;
  Image image;
  FlipDirection direction;
  _Flip(this.port, this.image, this.direction);
}

Future<void> _flip(_Flip p) async {
  final res = flip(p.image, p.direction);
  Isolate.exit(p.port, res);
}

/// Asynchronously flips the [src] image using the given [direction], which can
/// be one of: [FlipDirection.horizontal], [FlipDirection.vertical],
/// or [FlipDirection.both].
Future<Image> flipAsync(Image src, FlipDirection direction) async {
  final port = ReceivePort();
  await Isolate.spawn(_flip,
      _Flip(port.sendPort, src, direction));
  return await port.first as Image;
}

/// Asynchronously flip the [src] image vertically.
Future<Image> flipVerticalAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_flip,
      _Flip(port.sendPort, src, FlipDirection.vertical));
  return await port.first as Image;
}

/// Asynchronously flip the [src] image horizontally.
Future<Image> flipHorizontalAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_flip,
      _Flip(port.sendPort, src, FlipDirection.horizontal));
  return await port.first as Image;
}

/// Asynchronously flip the [src] image horizontally and vertically.
Future<Image> flipHorizontalVerticalAsync(Image src) async {
  final port = ReceivePort();
  await Isolate.spawn(_flip,
      _Flip(port.sendPort, src, FlipDirection.both));
  return await port.first as Image;
}
