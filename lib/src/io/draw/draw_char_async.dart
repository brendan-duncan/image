import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_char.dart';
import '../../font/bitmap_font.dart';
import '../../image/image.dart';

class _DrawChar {
  final SendPort port;
  final Image image;
  BitmapFont font;
  int x;
  int y;
  String char;
  Color? color;
  _DrawChar(this.port, this.image, this.font, this.x, this.y, this.char,
      this.color);
}

Future<Image> _drawChar(_DrawChar p) async {
  final res = drawChar(p.image, p.font, p.x, p.y, p.char, color: p.color);
  Isolate.exit(p.port, res);
}

/// Asynchronously call [drawChar].
Future<Image> drawCharAsync(Image image, BitmapFont font, int x, int y,
    String char, {Color? color}) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawChar,
      _DrawChar(port.sendPort, image, font, x, y, char, color));
  return await port.first as Image;
}
