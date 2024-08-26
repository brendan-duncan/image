import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('png', () {
      const buck24Hash = 817446904;
      Image? buck24Image;

      test('luminanceAlpha', () async {
        final png = (await decodePngFile('test/_data/png/png_LA.png'))!;
        expect(png.numChannels, equals(2));
        final rgba = png.convert(numChannels: 4);
        await encodePngFile('$testOutputPath/png/png_LA_rgba.png', rgba);
      });

      test('hungry_180', () async {
        final png = (await decodePngFile('test/_data/png/hungry_180.png'))!;
        flip(png, direction: FlipDirection.horizontal);
        encodePngFile('$testOutputPath/png/hungry_180_flip.png', png);
      });

      test('transparencyAnim', () async {
        final g1 = await decodePngFile('test/_data/png/g1.png');
        final g2 = await decodePngFile('test/_data/png/g2.png');
        final g3 = await decodePngFile('test/_data/png/g3.png');
        g1!.addFrame(g2);
        g1.addFrame(g3);

        await encodePngFile('$testOutputPath/png/transparencyAnim.png', g1);
      });

      group('b1_1', () {
        final image =
            Image(width: 32, height: 32, format: Format.uint1, numChannels: 1);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 1 : 0;
          p.r = c;
        }

        for (var filter in PngFilter.values) {
          test('b1_1_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b1_1_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b1_1', () {
        final image =
            Image(width: 32, height: 32, format: Format.uint1, numChannels: 1);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 1 : 0;
          p.r = c;
        }

        for (var filter in PngFilter.values) {
          test('b1_1_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b1_1_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b1_1p', () {
        final image = Image(
            width: 32, height: 32, format: Format.uint1, withPalette: true);
        image.palette!.setRgb(0, 255, 0, 0);
        image.palette!.setRgb(1, 0, 255, 0);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 1 : 0;
          p.index = c;
        }

        for (var filter in PngFilter.values) {
          test('b1_1p_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b1_p_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b2_1', () {
        final image =
            Image(width: 32, height: 32, format: Format.uint2, numChannels: 1);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 3 : 0;
          p.r = c;
        }

        for (var filter in PngFilter.values) {
          test('b2_1_${filter.name}', () {
            // should encode to grayscale
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b2_1_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b2_1p', () {
        final image = Image(
            width: 32, height: 32, format: Format.uint2, withPalette: true);
        for (var i = 0; i < 4; ++i) {
          image.palette!.setRgb(i, i * 85, i * 85, i * 85);
        }
        for (final p in image) {
          p.r = p.x >> 3;
        }

        for (var filter in PngFilter.values) {
          test('b2_1p_${filter.name}', () {
            // should encode to indexed
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b2_1p_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b4_1', () {
        final image =
            Image(width: 32, height: 32, format: Format.uint4, numChannels: 1);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 31 : 0;
          p.r = c;
        }

        for (var filter in PngFilter.values) {
          test('b4_1_${filter.name}', () {
            // should encode to grayscale
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b4_1_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b4_1p', () {
        final image = Image(
            width: 32, height: 32, format: Format.uint4, withPalette: true);
        for (var i = 0; i < 16; ++i) {
          image.palette!.setRgb(i, i * 17, i * 17, i * 17);
        }
        for (final p in image) {
          p.r = p.x >> 1;
        }

        for (var filter in PngFilter.values) {
          test('b4_1p_${filter.name}', () {
            // should encode to indexed
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b4_1p_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b8_3', () {
        final image = Image(width: 32, height: 32);
        for (final p in image) {
          final c = p.x < (32 - p.y) ? 255 : 0;
          p
            ..r = c
            ..g = c
            ..b = c;
        }

        for (var filter in PngFilter.values) {
          test('b8_3_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b8_3_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b8_3p', () {
        final image = Image(width: 32, height: 32, withPalette: true);
        for (var i = 0; i < 256; ++i) {
          image.palette!.setRgb(i, i, i, i);
        }
        for (final p in image) {
          p.r = p.x * 8;
        }

        for (var filter in PngFilter.values) {
          test('b8_3p_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b8_3p_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);
          });
        }
      });

      group('b16_3', () {
        final image = Image(width: 32, height: 32, format: Format.uint16);
        for (final p in image) {
          final c = p.x * 2114;
          p
            ..r = c
            ..g = c
            ..b = c;
        }

        for (var filter in PngFilter.values) {
          test('b8_3_${filter.name}', () {
            final png = encodePng(image, filter: filter);
            File('$testOutputPath/png/b16_3_${filter.name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);

            final image2 = PngDecoder().decode(png)!;
            expect(image2, isNotNull);
            testImageEquals(image, image2);

            for (final p in image2) {
              final c = p.x * 2114;
              expect(p, equals([c, c, c]));
            }
          });
        }
      });

      test('decode', () {
        final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
        final image = PngDecoder().decode(bytes)!;
        expect(image.width, equals(300));
        expect(image.height, equals(186));
        expect(image.numChannels, equals(3));
        expect(image.format, equals(Format.uint8));

        final hash = hashImage(image);
        expect(hash, equals(buck24Hash));

        buck24Image = image;
      });

      test('encode palette', () {
        final palette = PaletteUint8(256, 3);
        for (var i = 0; i < 256; ++i) {
          palette.setRgb(i, (i * 2) % 256, (i * 8) % 256, i);
        }
        final image =
            Image(width: 256, height: 256, numChannels: 1, palette: palette);
        for (final p in image) {
          p.index = p.x % 256;
        }

        final png = encodePng(image);
        File('$testOutputPath/png/encode_palette.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final image2 = decodePng(png);
        expect(image2!.width, equals(image.width));
        expect(image2.height, equals(image.height));
        final p2 = image2.iterator..moveNext();
        for (final p in image) {
          expect(p, equals(p2.current));
          p2.moveNext();
        }
      });

      test('decode palette', () {
        final bytes = File('test/_data/png/buck_8.png').readAsBytesSync();
        final image = PngDecoder().decode(bytes)!;
        expect(image.width, equals(300));
        expect(image.height, equals(186));
        expect(image.numChannels, equals(3));
        expect(image.format, equals(Format.uint8));
        expect(image.hasPalette, equals(true));

        final png = encodePng(image);
        File('$testOutputPath/png/decode_palette.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });

      test('encode filter:none', () {
        final png = PngEncoder(filter: PngFilter.none).encode(buck24Image!);
        final file = File('$testOutputPath/png/encode_filter_none.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final png2 = decodePng(file.readAsBytesSync());
        final hash = hashImage(png2!);
        expect(hash, equals(buck24Hash));
      });

      test('encode filter:sub', () {
        final png = PngEncoder(filter: PngFilter.sub).encode(buck24Image!);
        final file = File('$testOutputPath/png/encode_filter_sub.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final png2 = decodePng(file.readAsBytesSync());
        final hash = hashImage(png2!);
        expect(hash, equals(buck24Hash));
      });

      test('encode filter:up', () {
        final png = PngEncoder(filter: PngFilter.up).encode(buck24Image!);
        final file = File('$testOutputPath/png/encode_filter_up.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final png2 = decodePng(file.readAsBytesSync());
        final hash = hashImage(png2!);
        expect(hash, equals(buck24Hash));
      });

      test('encode filter:average', () {
        final png = PngEncoder(filter: PngFilter.sub).encode(buck24Image!);
        final file = File('$testOutputPath/png/encode_filter_average.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final png2 = decodePng(file.readAsBytesSync());
        final hash = hashImage(png2!);
        expect(hash, equals(buck24Hash));
      });

      test('encode filter:paeth', () {
        final png = PngEncoder().encode(buck24Image!);
        final file = File('$testOutputPath/png/encode_filter_paeth.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final png2 = decodePng(file.readAsBytesSync());
        final hash = hashImage(png2!);
        expect(hash, equals(buck24Hash));
      });

      test('decodeAnimation', () {
        const files = [
          ['test/_data/png/apng/test_apng.png', 2, 'test_apng'],
          ['test/_data/png/apng/test_apng2.png', 60, 'test_apng2'],
          ['test/_data/png/apng/test_apng3.png', 19, 'test_apng3']
        ];

        for (var f in files) {
          final bytes = File(f[0] as String).readAsBytesSync();
          final anim = PngDecoder().decode(bytes)!;
          expect(anim.numFrames, equals(f[1]));

          for (var i = 0; i < anim.numFrames; ++i) {
            final png = PngEncoder().encode(anim.getFrame(i));
            File('$testOutputPath/png/${f[2]}-$i.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
          }
        }
      });

      test('encodeAnimation', () {
        final anim = Image(width: 480, height: 120)..loopCount = 10;
        for (var i = 0; i < 10; i++) {
          final frame = i == 0 ? anim : anim.addFrame();
          drawString(frame, i.toString(), font: arial48, x: 100, y: 60);
        }

        final png = encodePng(anim);
        File('$testOutputPath/png/encodeAnimation.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });

      test('encodeAnimation with mulitple single frame Images', () {
        final encoder = PngEncoder()..start(10);
        for (var i = 0; i < 10; i++) {
          final frame = Image(width: 480, height: 120)..loopCount = 10;
          drawString(frame, i.toString(), font: arial48, x: 100, y: 60);
          encoder.addFrame(frame);
        }

        final png = encoder.finish()!;
        File('$testOutputPath/png/encodeAnimation.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });

      test('textData', () {
        final img = Image(width: 16, height: 16, textData: {"foo": "bar"});
        final png = PngEncoder().encode(img);
        final img2 = PngDecoder().decode(png);
        expect(img2?.width, equals(img.width));
        expect(img2?.textData?["foo"], equals("bar"));
      });

      test('pHYs', () {
        final img = Image(width: 16, height: 16);
        const phys1 = PngPhysicalPixelDimensions(
            xPxPerUnit: 1000,
            yPxPerUnit: 1000,
            unitSpecifier: PngPhysicalPixelDimensions.unitMeter);
        final png1 = PngEncoder(pixelDimensions: phys1).encode(img);
        final dec1 = PngDecoder()..decode(png1);
        expect(dec1.info.pixelDimensions, phys1);

        final phys2 = PngPhysicalPixelDimensions.dpi(144, 288);
        final png2 = PngEncoder(pixelDimensions: phys2).encode(img);
        final dec2 = PngDecoder()..decode(png2);
        expect(dec2.info.pixelDimensions, isNot(phys1));
        expect(dec2.info.pixelDimensions, phys2);
      });

      test('iCCP', () {
        final bytes = File('test/_data/png/iCCP.png').readAsBytesSync();
        final image = PngDecoder().decode(bytes)!;
        expect(image.iccProfile, isNotNull);
        expect(image.iccProfile!.data, isNotNull);

        final png = PngEncoder().encode(image);

        final image2 = PngDecoder().decode(png)!;
        expect(image2.iccProfile, isNotNull);
        expect(image2.iccProfile!.data, isNotNull);
        expect(image2.iccProfile!.data.length,
            equals(image.iccProfile!.data.length));
      });

      final dir = Directory('test/_data/png');
      final files = dir.listSync();

      for (var f in files) {
        if (f is! File || !f.path.endsWith('.png')) {
          continue;
        }

        // PngSuite File naming convention:
        // filename:                                g04i2c08.png
        //                                          || ||||
        //  test feature (in this case gamma) ------+| ||||
        //  parameter of test (here gamma-value) ----+ ||||
        //  interlaced or non-interlaced --------------+|||
        //  color-type (numerical) ---------------------+||
        //  color-type (descriptive) --------------------+|
        //  bit-depth ------------------------------------+
        //
        //  color-type:
        //
        //    0g - grayscale
        //    2c - rgb color
        //    3p - paletted
        //    4a - grayscale + alpha channel
        //    6a - rgb color + alpha channel
        //    bit-depth:
        //      01 - with color-type 0, 3
        //      02 - with color-type 0, 3
        //      04 - with color-type 0, 3
        //      08 - with color-type 0, 2, 3, 4, 6
        //      16 - with color-type 0, 2, 4, 6
        //      interlacing:
        //        n - non-interlaced
        //        i - interlaced
        final name = f.uri.pathSegments.last;

        test(name, () {
          final file = f;

          // x* png's are corrupted and are supposed to crash.
          if (name.startsWith('x')) {
            try {
              final image = PngDecoder().decode(file.readAsBytesSync());
              expect(image, isNull);
            } catch (e) {
              // noop
            }
          } else {
            final anim = PngDecoder().decode(file.readAsBytesSync());
            expect(anim, isNotNull);
            if (anim != null) {
              if (anim.numFrames == 1) {
                final png = PngEncoder().encode(anim);
                File('$testOutputPath/png/$name.png')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(png);

                final i1 = PngDecoder().decode(png);
                expect(i1, isNotNull);
                expect(i1!.width, equals(anim.width));
                expect(i1.height, equals(anim.height));
                expect(i1.format, equals(anim.format));
                expect(i1.numChannels, equals(anim.numChannels));
                for (final p in i1) {
                  final p2 = anim.getPixel(p.x, p.y);
                  expect(p, equals(p2));
                }
              } else {
                for (var i = 0; i < anim.numFrames; ++i) {
                  final png = PngEncoder().encode(anim.getFrame(i));
                  File('$testOutputPath/png/$name-$i.png')
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(png);
                }
              }
            }
          }
        });
      }
    });
  });
}
