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

Future<void> _drawChar(_DrawChar p) async {
  drawChar(p.image, p.font, p.x, p.y, p.char, color: p.color);
  Isolate.exit(p.port);
}

/// Asynchronously call [drawChar].
Future<void> drawCharAsync(Image image, BitmapFont font, int x, int y,
    String char, {Color? color}) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawChar,
      _DrawChar(port.sendPort, image, font, x, y, char, color));
  return port.first;
}
