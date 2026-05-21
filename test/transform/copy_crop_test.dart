import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('crop with radius', () async {
      final g1 = await decodeGifFile('test/_data/gif/homer.gif');
      final g2 = copyCrop(
        g1!,
        x: 0,
        y: 0,
        width: 500, // this is just the width of the original animation
        height: 375, // this is just the height of the original animation
        radius: 100,
      );
      await encodeGifFile('$testOutputPath/transform/copyCrop_radius.gif', g2);
      await encodePngFile('$testOutputPath/transform/copyCrop_radius.png', g2);
    });

    test('copyCrop', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = PngDecoder().decode(bytes)!;

      final i0_1 = copyCrop(i0, x: 50, y: 50, width: 100, height: 100);
      expect(i0_1.width, equals(100));
      expect(i0_1.height, equals(100));
      expect(i0_1.format, equals(i0.format));
      File('$testOutputPath/transform/copyCrop.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_1));

      final i1 = i0.convert(numChannels: 4);
      final i0_2 = copyCrop(
        i1,
        x: 50,
        y: 50,
        width: 100,
        height: 100,
        radius: 20,
      );
      expect(i0_2.width, equals(100));
      expect(i0_2.height, equals(100));
      expect(i0_2.format, equals(i0.format));
      File('$testOutputPath/transform/copyCrop_rounded.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_2));
    });

    // Result dimensions exactly match the requested crop size.
    test('copyCrop result has the requested dimensions', () {
      final src = solidImage(64, 64, ColorRgb8(100, 150, 200));
      final result = copyCrop(src, x: 10, y: 10, width: 30, height: 20);
      expect(result.width, equals(30));
      expect(result.height, equals(20));
    });

    // copyCrop does not mutate the source image.
    test('copyCrop does not mutate the source', () {
      final src = horizontalGradient(64, 32);
      final orig = src.clone();
      copyCrop(src, x: 0, y: 0, width: 32, height: 16);
      testImageEquals(src, orig);
    });

    // Pixel (i,j) of the crop must equal source pixel (x+i, y+j).
    test('copyCrop pixel values match source at the crop offset', () {
      // Use a horizontal gradient so every column has a distinct value.
      final src = horizontalGradient(64, 32);
      const cropX = 8;
      const cropY = 4;
      const cropW = 20;
      const cropH = 10;
      final result = copyCrop(
          src, x: cropX, y: cropY, width: cropW, height: cropH);

      for (var j = 0; j < cropH; j++) {
        for (var i = 0; i < cropW; i++) {
          final sp = src.getPixel(cropX + i, cropY + j);
          final dp = result.getPixel(i, j);
          expect(dp.r, equals(sp.r),
              reason: 'pixel ($i,$j) red: crop vs '
                  'source(${cropX + i},${cropY + j})');
        }
      }
    });

    // Cropping the full image returns an image pixel-equal to the source.
    test('copyCrop of the full image equals the source', () {
      final src = quadrantImage(16, 16);
      final result = copyCrop(src, x: 0, y: 0, width: 16, height: 16);
      testImageEquals(result, src);
    });

    // Cropping a solid-color image still yields a solid-color image.
    test('copyCrop of solid image preserves color', () {
      final src = solidImage(32, 32, ColorRgb8(255, 128, 0));
      final result = copyCrop(src, x: 5, y: 5, width: 10, height: 10);
      expectSolidColor(result, ColorRgb8(255, 128, 0));
    });
  });
}
