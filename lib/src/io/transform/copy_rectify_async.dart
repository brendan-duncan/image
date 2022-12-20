import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_rectify.dart';
import '../../util/point.dart';

class _CopyRectify {
  final SendPort port;
  Image image;
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;
  Image? toImage;
  _CopyRectify(this.port, this.image, this.topLeft, this.topRight,
      this.bottomLeft, this.bottomRight, this.toImage);
}

Future<void> _copyRectify(_CopyRectify p) async {
  final res = copyRectify(p.image, topLeft: p.topLeft, topRight: p.topRight,
    bottomLeft: p.bottomLeft, bottomRight: p.bottomRight, toImage: p.toImage);
  Isolate.exit(p.port, res);
}

/// Returns a copy of the [src] image, where the given rectangle
/// has been mapped to the full image.
Future<Image> copyRectifyAsync(Image src, { required Point topLeft,
    required Point topRight,
    required Point bottomLeft,
    required Point bottomRight,
    Image? toImage }) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyRectify,
      _CopyRectify(port.sendPort, src, topLeft, topRight, bottomLeft,
          bottomRight, toImage));
  return await port.first as Image;
}
