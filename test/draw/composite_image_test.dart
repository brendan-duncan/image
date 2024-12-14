import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('compositeImage2', () async {
      final mask = (await decodePngFile('test/_data/png/logo.png'))!;
      final fg = (await decodePngFile('test/_data/png/colors.png'))!;
      final bg = (await decodePngFile('test/_data/png/buck_24.png'))!;

      compositeImage(bg, fg, mask: mask);

      File('$testOutputPath/draw/compositeImage2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(bg));
    });

    test('compositeImage', () async {
      final i0 = Image(width: 256, height: 256);
      final i1 = Image(width: 256, height: 256, numChannels: 4);

      i0.clear(ColorRgba8(255, 0, 0, 255));
      for (final p in i1) {
        p
          ..r = p.x
          ..g = p.y
          ..a = p.y;
      }

      compositeImage(i0, i1, dstX: 50, dstY: 50, dstW: 100, dstH: 100);
      compositeImage(i0, i1, dstX: 100, dstY: 100, dstW: 100, dstH: 100);

      File('$testOutputPath/draw/compositeImage_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      var fg = decodeTga(File('test/_data/tga/globe.tga').readAsBytesSync())!;
      fg = fg.convert(numChannels: 4);
      for (final p in fg) {
        if (p.r == 0 && p.g == 0 && p.b == 0) {
          p.a = 0;
        }
      }

      final origBg = (await decodePngFile('test/_data/png/buck_24.png'))!;

      {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50);
        File('$testOutputPath/draw/compositeImage.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));
      }

      {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50, dstW: 200, dstH: 200);
        File('$testOutputPath/draw/compositeImage_scaled.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));
      }

      for (var blend in BlendMode.values) {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50, blend: blend);
        File('$testOutputPath/draw/compositeImage_${blend.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));
      }

      final mask = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
            x: 128, y: 128, radius: 30, color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 5);

      final fgCmd = Command()..image(fg);

      await (Command()
            ..image(origBg)
            ..copy()
            ..compositeImage(fgCmd, dstX: 50, dstY: 50, mask: mask)
            ..writeToFile('$testOutputPath/draw/compositeImage_mask.png'))
          .execute();
    });
  });
}
