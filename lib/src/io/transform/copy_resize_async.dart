import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_resize.dart';
import '../../util/interpolation.dart';

class _CopyResize {
  final SendPort port;
  Image image;
  int? width;
  int? height;
  Interpolation interpolation;
  _CopyResize(this.port, this.image, this.width, this.height,
      this.interpolation);
}

Future<void> _copyResize(_CopyResize p) async {
  final res = copyResize(p.image, width: p.width,
      height: p.height, interpolation: p.interpolation);
  Isolate.exit(p.port, res);
}

/// Asynchronously resizes a copy [src] Image.
/// If [height] isn't specified, then it will be determined by the aspect
/// ratio of [src] and [width].
/// If [width] isn't specified, then it will be determined by the aspect ratio
/// of [src] and [height].
Future<Image> copyResizeAsync(Image src,
    {int? width, int? height,
      Interpolation interpolation = Interpolation.nearest}) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyResize,
      _CopyResize(port.sendPort, src, width, height, interpolation));
  return await port.first as Image;
}
