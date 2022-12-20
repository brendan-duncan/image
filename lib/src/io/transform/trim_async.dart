import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/trim.dart';

class _Trim {
  final SendPort port;
  Image image;
  TrimMode mode;
  Trim sides;
  _Trim(this.port, this.image, this.mode, this.sides);
}

Future<void> _trim(_Trim p) async {
  final res = trim(p.image, mode: p.mode, sides: p.sides);
  Isolate.exit(p.port, res);
}

Future<void> _findTrim(_Trim p) async {
  final res = findTrim(p.image, mode: p.mode, sides: p.sides);
  Isolate.exit(p.port, res);
}

/// Automatically crops the image by finding the corners of the image that
/// meet the [mode] criteria (not transparent or a different color).
///
/// [mode] can be either [TrimMode.transparent], [TrimMode.topLeftColor] or
/// [TrimMode.bottomRightColor].
///
/// [sides] can be used to control which sides of the image get trimmed,
/// and can be any combination of [Trim.top], [Trim.bottom], [Trim.left],
/// and [Trim.right].
Future<Image> trimAsync(Image src,
    {TrimMode mode = TrimMode.transparent, Trim sides = Trim.all}) async {
  final port = ReceivePort();
  await Isolate.spawn(_trim,
      _Trim(port.sendPort, src, mode, sides));
  return await port.first as Image;
}

/// Find the crop area to be used by the trim function. Returns the
/// coordinates as [x, y, width, height]. You could pass these coordinates
/// to the copyCrop function to crop the image.
Future<List<int>> findTrimAsync(Image src,
    {TrimMode mode = TrimMode.transparent, Trim sides = Trim.all}) async {
  final port = ReceivePort();
  await Isolate.spawn(_findTrim,
      _Trim(port.sendPort, src, mode, sides));
  return await port.first as List<int>;
}
