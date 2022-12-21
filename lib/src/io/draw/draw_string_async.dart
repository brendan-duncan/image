import 'dart:isolate';

import '../../color/color.dart';
import '../../draw/draw_string.dart';
import '../../font/bitmap_font.dart';
import '../../image/image.dart';

enum _DrawStringMode {
  drawString,
  drawStringWrap,
  drawStringCentered
}

class _DrawString {
  final SendPort port;
  final Image image;
  BitmapFont font;
  int? x;
  int? y;
  String string;
  Color? color;
  _DrawStringMode mode;
  bool rightJustify;
  _DrawString(this.port, this.image, this.font, this.x, this.y, this.string,
      this.color, this.mode, this.rightJustify);
}

Future<Image> _drawString(_DrawString p) async {
  Image res;
  switch (p.mode) {
    case _DrawStringMode.drawString:
      res = drawString(p.image, p.font, p.x!, p.y!, p.string, color: p.color,
          rightJustify: p.rightJustify);
      break;
    case _DrawStringMode.drawStringWrap:
      res = drawStringWrap(p.image, p.font, p.x!, p.y!, p.string,
          color: p.color);
      break;
    case _DrawStringMode.drawStringCentered:
      res = drawStringCentered(p.image, p.font, p.string,
          x: p.x, y: p.y, color: p.color);
      break;
  }

  Isolate.exit(p.port, res);
}

/// Asynchronous call to [drawString].
Future<Image> drawStringAsync(Image image, BitmapFont font, int x, int y,
    String string, { Color? color, bool rightJustify = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawString,
      _DrawString(port.sendPort, image, font, x, y, string, color,
          _DrawStringMode.drawString, rightJustify));
  return await port.first as Image;
}

/// Asynchronous call to [drawStringWrap].
Future<Image> drawStringWrapAsync(Image image, BitmapFont font, int x, int y,
    String string, { Color? color }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawString,
      _DrawString(port.sendPort, image, font, x, y, string, color,
          _DrawStringMode.drawStringWrap, false));
  return await port.first as Image;
}

/// Asynchronous call to [drawStringCentered].
Future<Image> drawStringCenteredAsync(Image image, BitmapFont font,
    String string, { int? x, int? y, Color? color }) async {
  final port = ReceivePort();
  await Isolate.spawn(_drawString,
      _DrawString(port.sendPort, image, font, x, y, string, color,
          _DrawStringMode.drawStringCentered, false));
  return await port.first as Image;
}
