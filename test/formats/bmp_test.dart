import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('bmp', () {
      final dir = Directory('test/_data/bmp');
      final files = dir.listSync().whereType<File>();
      for (var f in files.whereType<File>()) {
        if (!f.path.endsWith('.bmp')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () async {
          final image = await (Command()
                ..decodeBmp(f.readAsBytesSync())
                ..writeToFile('$testOutputPath/bmp/$name.bmp'))
              .getImage();
          expect(image, isNotNull);

          final image2 = await (Command()
                ..decodeBmpFile('$testOutputPath/bmp/$name.bmp')
                ..writeToFile('$testOutputPath/bmp/${name}2.bmp'))
              .getImage();
          expect(image2, isNotNull);

          testImageEquals(image2!, image!);
        });
      }

      // Issue #729: a non-BMP file that merely starts with the 'BM' signature
      // should be rejected rather than misdetected as a BMP and crashing.
      test('rejects a non-BMP file with a BM signature', () {
        final notBmp = Uint8List.fromList([
          0x42, 0x4d, 0x4c, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x00, 0x00, 0x1a, 0x00, 0x00, 0x00, 0x0c, 0x00, //
          0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        ]);
        expect(decodeBmp(notBmp), isNull);
        expect(() => decodeImage(notBmp), returnsNormally);
      });

      test('uint1', () async {
        await (Command()
              ..createImage(width: 256, height: 256)
              ..filter((image) {
                for (final p in image) {
                  p
                    ..r = p.x % 255
                    ..g = p.y % 255;
                }
                return image;
              })
              ..grayscale()
              ..quantize(numberOfColors: 2, dither: DitherKernel.floydSteinberg)
              ..convert(format: Format.uint1, withPalette: true)
              ..writeToFile('$testOutputPath/bmp/bmp_1.bmp'))
            .execute();
      });

      test('uint4', () async {
        await (Command()
              ..createImage(width: 256, height: 256, format: Format.uint4)
              ..filter((image) {
                for (final p in image) {
                  p
                    ..r = p.x ~/ p.maxChannelValue
                    ..g = p.y ~/ p.maxChannelValue
                    ..a = p.maxChannelValue - (p.y ~/ p.maxChannelValue);
                }
                return image;
              })
              ..writeToFile('$testOutputPath/bmp/bmp_16.bmp'))
            .execute();
      });
    });
  });
}
