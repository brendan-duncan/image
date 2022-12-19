import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void drawPixelTest() {
  test('drawPixel.uint8', () {
    final i0 = Image(256, 256);
    for (int y = 0; y < 256; ++y) {
      for (int x = 0; x < 256; ++x) {
        drawPixel(i0, x, y, ColorRgba8(x, y));
      }
    }
    File('$tmpPath/out/draw/draw_pixel_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));

    // Overlay blue pixels at half transparency
    for (int y = 0; y < 256; ++y) {
      for (int x = 0; x < 256; ++x) {
        drawPixel(i0, x, y, ColorRgba8(0, 0, 255, 128));
      }
    }
    File('$tmpPath/out/draw/draw_pixel_1.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
