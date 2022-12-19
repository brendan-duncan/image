import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void drawImageTest() {
  test('drawImage', () {
    final i0 = Image(256, 256);
    final i1 = Image(256, 256, numChannels: 4);

    i0.clear(ColorRgba8(255));
    for (var p in i1) {
      p..r = p.x
      ..g = p.y
      ..a = p.y;
    }

    drawImage(i0, i1, dstX: 50, dstY: 50, dstW: 100, dstH: 100);
    drawImage(i0, i1, dstX: 100, dstY: 100, dstW: 100, dstH: 100);

    File('$tmpPath/out/draw/drawImage_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));

    var fg = decodeTga(File('test/_data/tga/globe.tga').readAsBytesSync())!;
    fg = fg.convert(numChannels: 4);
    for (var p in fg) {
      if (p.r == 0 && p.g == 0 && p.b == 0) {
        p.a = 0;
      }
    }
    var bg = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
    drawImage(bg, fg, dstX: 50, dstY: 50);
    File('$tmpPath/out/draw/drawImage_1.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(bg));

    bg = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
    drawImage(bg, fg, dstX: 50, dstY: 50, dstW: 200, dstH: 200);
    File('$tmpPath/out/draw/drawImage_3.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(bg));
  });
}
