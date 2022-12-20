import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/copy_resize_crop_square.dart';

class _CopyResizeCropSquare {
  final SendPort port;
  Image image;
  int size;
  _CopyResizeCropSquare(this.port, this.image, this.size);
}

Future<void> _copyResizeCropSquare(_CopyResizeCropSquare p) async {
  final res = copyResizeCropSquare(p.image, p.size);
  Isolate.exit(p.port, res);
}

/// Returns a resized and square cropped copy of the [src] image of [size] size.
Future<Image> copyResizeAsync(Image src, int size) async {
  final port = ReceivePort();
  await Isolate.spawn(_copyResizeCropSquare,
      _CopyResizeCropSquare(port.sendPort, src, size));
  return await port.first as Image;
}
