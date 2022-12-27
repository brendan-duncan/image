import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawImage', () {
      final i0 = Image(width: 256, height: 256);
      final i1 = Image(width: 256, height: 256, numChannels: 4);

      i0.clear(ColorRgba8(255));
      for (var p in i1) {
        p..r = p.x
        ..g = p.y
        ..a = p.y;
      }

      drawImage(i0, i1, dstX: 50, dstY: 50, dstW: 100, dstH: 100);
      drawImage(i0, i1, dstX: 100, dstY: 100, dstW: 100, dstH: 100);

      File('$testOutputPath/draw/draw_image_1.png')
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
      File('$testOutputPath/draw/draw_image.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(bg));

      bg = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      drawImage(bg, fg, dstX: 50, dstY: 50, dstW: 200, dstH: 200);
      File('$testOutputPath/draw/draw_image_2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(bg));
    });
  });
}
