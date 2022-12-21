import 'dart:isolate';

import '../../color/color.dart';
import '../../filter/drop_shadow.dart';
import '../../image/image.dart';

class _DropShadow {
  final SendPort port;
  final Image src;
  int hShadow;
  int vShadow;
  int blur;
  Color? shadowColor;
  _DropShadow(this.port, this.src, this.hShadow, this.vShadow, this.blur,
      this.shadowColor);
}

Future<Image> _dropShadow(_DropShadow p) async {
  final res = dropShadow(p.src, p.hShadow, p.vShadow, p.blur,
      shadowColor: p.shadowColor);
  Isolate.exit(p.port, res);
}

/// Asynchronous call to [dropShadow].
Future<Image> dropShadowAsync(Image src, int hShadow, int vShadow, int blur,
    { Color? shadowColor }) async {
  final port = ReceivePort();
  await Isolate.spawn(_dropShadow, _DropShadow(port.sendPort, src, hShadow,
      vShadow, blur, shadowColor));
  return await port.first as Image;
}
