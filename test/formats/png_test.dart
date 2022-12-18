import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void PngTest() {
  group('PNG', () {
    const _buck24Hash = 817446904;
    Image? buck24Image;

    group('b1_1', () {
      final image = Image(32, 32, format: Format.uint1, numChannels: 1);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 1 : 0;
        p.r = c;
      }

      for (var filter in PngFilter.values) {
        test('b1_1_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b1_1_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b1_1', () {
      final image = Image(32, 32, format: Format.uint1, numChannels: 1);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 1 : 0;
        p.r = c;
      }

      for (var filter in PngFilter.values) {
        test('b1_1_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b1_1_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b1_1p', () {
      final image = Image(32, 32, format: Format.uint1, withPalette: true);
      image.palette!.setColor(0, 255);
      image.palette!.setColor(1, 0, 255);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 1 : 0;
        p.index = c;
      }

      for (var filter in PngFilter.values) {
        test('b1_1p_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b1_p_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b2_1', () {
      final image = Image(32, 32, format: Format.uint2, numChannels: 1);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 3 : 0;
        p.r = c;
      }

      for (var filter in PngFilter.values) {
        test('b2_1_${filter.name}', () {
          // should encode to grayscale
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b2_1_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b2_1p', () {
      final image = Image(32, 32, format: Format.uint2, withPalette: true);
      for (var i = 0; i < 4; ++i) {
        image.palette!.setColor(i, i * 85, i * 85, i * 85);
      }
      for (var p in image) {
        p.r = p.x >> 3;
      }

      for (var filter in PngFilter.values) {
        test('b2_1p_${filter.name}', () {
          // should encode to indexed
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b2_1p_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b4_1', () {
      final image = Image(32, 32, format: Format.uint4, numChannels: 1);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 31 : 0;
        p.r = c;
      }

      for (var filter in PngFilter.values) {
        test('b4_1_${filter.name}', () {
          // should encode to grayscale
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b4_1_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b4_1p', () {
      final image = Image(32, 32, format: Format.uint4, withPalette: true);
      for (var i = 0; i < 16; ++i) {
        image.palette!.setColor(i, i * 17, i * 17, i * 17);
      }
      for (var p in image) {
        p.r = p.x >> 1;
      }

      for (var filter in PngFilter.values) {
        test('b4_1p_${filter.name}', () {
          // should encode to indexed
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b4_1p_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b8_3', () {
      final image = Image(32, 32);
      for (var p in image) {
        final c = p.x < (32 - p.y) ? 255 : 0;
        p.r = c;
        p.g = c;
        p.b = c;
      }

      for (var filter in PngFilter.values) {
        test('b8_3_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b8_3_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b8_3p', () {
      final image = Image(32, 32, withPalette: true);
      for (var i = 0; i < 256; ++i) {
        image.palette!.setColor(i, i, i, i);
      }
      for (var p in image) {
        p.r = p.x * 8;
      }

      for (var filter in PngFilter.values) {
        test('b8_3p_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b8_3p_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);
        });
      }
    });

    group('b16_3', () {
      final image = Image(32, 32, format: Format.uint16);
      for (var p in image) {
        final c = p.x * 2114;
        p.r = c;
        p.g = c;
        p.b = c;
      }

      for (var filter in PngFilter.values) {
        test('b8_3_${filter.name}', () {
          final png = encodePng(image, filter: filter);
          File('$tmpPath/out/png/b16_3_${filter.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

          final image2 = PngDecoder().decodeImage(png)!;
          expect(image2, isNotNull);
          testImageEquals(image, image2);

          for (var p in image2) {
            final c = p.x * 2114;
            expect(p, equals([c, c, c]));
          }
        });
      }
    });

    test('decode', () {
      final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;
      expect(image.width, equals(300));
      expect(image.height, equals(186));
      expect(image.numChannels, equals(3));
      expect(image.format, equals(Format.uint8));

      final hash = hashImage(image);
      expect(hash, equals(_buck24Hash));

      buck24Image = image;
    });

    test('encode palette', () {
      final palette = PaletteUint8(256, 3);
      for (var i = 0; i < 256; ++i) {
        palette.setColor(i, (i * 2) % 256, (i * 8) % 256, i);
      }
      final image = Image(256, 256, numChannels: 1, palette: palette);
      for (var p in image) {
        p.index = p.x % 256;
      }

      final png = encodePng(image);
      File('$tmpPath/out/png/encode_palette.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final image2 = decodePng(png);
      expect(image2!.width, equals(image.width));
      expect(image2.height, equals(image.height));
      final p2 = image2.iterator;
      p2.moveNext();
      for (var p in image) {
        expect(p, equals(p2.current));
        p2.moveNext();
      }
    });

    test('decode palette', () {
      final bytes = File('test/data/png/buck_8.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;
      expect(image.width, equals(300));
      expect(image.height, equals(186));
      expect(image.numChannels, equals(3));
      expect(image.format, equals(Format.uint8));
      expect(image.hasPalette, equals(true));

      final png = encodePng(image);
      File('$tmpPath/out/png/decode_palette.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });

    test('encode filter:none', () {
      final png = PngEncoder(filter: PngFilter.none).encodeImage(buck24Image!);
      final file = File('$tmpPath/out/png/encode_filter_none.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final png2 = decodePng(file.readAsBytesSync());
      final hash = hashImage(png2!);
      expect(hash, equals(_buck24Hash));
    });

    test('encode filter:sub', () {
      final png = PngEncoder(filter: PngFilter.sub).encodeImage(buck24Image!);
      final file = File('$tmpPath/out/png/encode_filter_sub.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final png2 = decodePng(file.readAsBytesSync());
      final hash = hashImage(png2!);
      expect(hash, equals(_buck24Hash));
    });

    test('encode filter:up', () {
      final png = PngEncoder(filter: PngFilter.up).encodeImage(buck24Image!);
      final file = File('$tmpPath/out/png/encode_filter_up.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final png2 = decodePng(file.readAsBytesSync());
      final hash = hashImage(png2!);
      expect(hash, equals(_buck24Hash));
    });

    test('encode filter:average', () {
      final png = PngEncoder(filter: PngFilter.sub).encodeImage(buck24Image!);
      final file = File('$tmpPath/out/png/encode_filter_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final png2 = decodePng(file.readAsBytesSync());
      final hash = hashImage(png2!);
      expect(hash, equals(_buck24Hash));
    });

    test('encode filter:paeth', () {
      final png = PngEncoder().encodeImage(buck24Image!);
      final file = File('$tmpPath/out/png/encode_filter_paeth.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final png2 = decodePng(file.readAsBytesSync());
      final hash = hashImage(png2!);
      expect(hash, equals(_buck24Hash));
    });

    test('decodeAnimation', () {
      var files = [
        ['test/data/png/apng/test_apng.png', 2, 'test_apng'],
        ['test/data/png/apng/test_apng2.png', 60, 'test_apng2'],
        ['test/data/png/apng/test_apng3.png', 19, 'test_apng3']
      ];

      for (var f in files) {
        final bytes = File(f[0] as String).readAsBytesSync();
        final anim = PngDecoder().decodeAnimation(bytes)!;
        expect(anim.length, equals(f[1]));

        for (var i = 0; i < anim.length; ++i) {
          final png = PngEncoder().encodeImage(anim[i]);
          File('$tmpPath/out/png/${f[2]}-$i.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
        }
      }
    });

    test('encodeAnimation', () {
      final anim = Animation();
      anim.loopCount = 10;
      for (var i = 0; i < 10; i++) {
        final image = Image(480, 120);
        drawString(image, arial_48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      final png = encodePngAnimation(anim);
      File('$tmpPath/out/png/encodeAnimation.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });


    test('textData', () {
      final img = Image(16, 16, textData: {"foo":"bar"});
      final png = PngEncoder().encodeImage(img);
      final img2 = PngDecoder().decodeImage(png);
      expect(img2?.width, equals(img.width));
      expect(img2?.textData?["foo"], equals("bar"));
    });

    test('iCCP', () {
      final bytes = File('test/data/png/iCCP.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;
      expect(image.iccProfile, isNotNull);
      expect(image.iccProfile!.data, isNotNull);

      final png = PngEncoder().encodeImage(image);

      final image2 = PngDecoder().decodeImage(png)!;
      expect(image2.iccProfile, isNotNull);
      expect(image2.iccProfile!.data, isNotNull);
      expect(image2.iccProfile!.data.length,
          equals(image.iccProfile!.data.length));
    });

    final dir = Directory('test/data/png');
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
            final image = PngDecoder().decodeImage(file.readAsBytesSync());
            expect(image, isNull);
          } catch (e) {
            // noop
          }
        } else {
          final anim = PngDecoder().decodeAnimation(file.readAsBytesSync());
          expect(anim, isNotNull);
          if (anim != null) {
            if (anim.length == 1) {
              final png = PngEncoder().encodeImage(anim[0]);
              File('$tmpPath/out/png/$name.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png);

              final i1 = PngDecoder().decodeImage(png);
              expect(i1, isNotNull);
              expect(i1!.width, equals(anim[0].width));
              expect(i1.height, equals(anim[0].height));
              expect(i1.format, equals(anim[0].format));
              expect(i1.numChannels, equals(anim[0].numChannels));
              for (var p in i1) {
                var p2 = anim[0].getPixel(p.x, p.y);
                expect(p, equals(p2));
              }
            } else {
              for (var i = 0; i < anim.length; ++i) {
                final png = PngEncoder().encodeImage(anim[i]);
                File('$tmpPath/out/png/$name-$i.png')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(png);
              }
            }
          }
        }
      });
    }
  });
}
