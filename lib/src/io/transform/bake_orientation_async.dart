import 'dart:isolate';

import '../../image/image.dart';
import '../../transform/bake_orientation.dart';

class _BakeOrientation {
  final SendPort port;
  Image image;
  _BakeOrientation(this.port, this.image);
}

Future<void> _bakeOrientation(_BakeOrientation p) async {
  final res = bakeOrientation(p.image);
  Isolate.exit(p.port, res);
}

/// If [image] has an orientation value in its exif data, this will rotate the
/// image so that it physically matches its orientation. This can be used to
/// bake the orientation of the image for image formats that don't support exif
/// data.
Future<Image> bakeOrientationAsync(Image image) async {
  final port = ReceivePort();
  await Isolate.spawn(_bakeOrientation,
      _BakeOrientation(port.sendPort, image));
  return await port.first as Image;
}
