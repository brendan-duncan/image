import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyResize nearest', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(img, width: 64);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize average', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 64,
        interpolation: Interpolation.average,
      );
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 64,
        interpolation: Interpolation.linear,
      );
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_linear.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize cubic', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(img, width: 64, interpolation: Interpolation.cubic);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_cubic.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 640,
        height: 640,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/copyResize_maintainAspect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect palette', () {
      final img = decodePng(
        File('test/_data/png/buck_8.png').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 640,
        height: 640,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/copyResize_maintainAspect_palette.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect 2', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = copyResize(
        i0,
        width: 200,
        height: 200,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/copyResize_maintainAspect_2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 3', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(
        i0,
        width: 200,
        height: 200,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/copyResize_maintainAspect_3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 4', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = copyResize(
        i0,
        width: 50,
        height: 100,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(50));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/copyResize_maintainAspect_4.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(
        i0,
        width: 100,
        height: 50,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(100));
      expect(i1.height, equals(50));
      File('$testOutputPath/transform/copyResize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(
        i0,
        width: 100,
        height: 500,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(100));
      expect(i1.height, equals(500));
      File('$testOutputPath/transform/copyResize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 6', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(
        i0,
        width: 500,
        height: 100,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(500));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/copyResize_maintainAspect_6.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize palette', () async {
      final img = await decodePngFile('test/_data/png/test.png');
      final i0 = copyResize(
        img!,
        width: 64,
        interpolation: Interpolation.cubic,
      );
      await encodePngFile(
        '$testOutputPath/transform/copyResize_palette.png',
        i0,
      );
    });

    test('copyResize nearest smaller color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(img, width: 64); // 256x256 => 64x64
      expect(i0.width, equals(64));
      expect(i0.height, equals(64));
      for (int y = 0; y < 64; y += 6) {
        for (int x = 0; x < 64; x += 8) {
          expect(
            i0.getPixel(x, y),
            equals(img.getPixel(x * 4, y * 4)),
            reason: 'Pixel color at ($x,$y) in resized image is not correct',
          );
        }
      }
      File('$testOutputPath/transform/copyResize_color_nearest_smaller_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize nearest larger color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 360,
      ); // 256x256 => 360x360 = 1.40625 times each side
      expect(i0.width, equals(360));
      expect(i0.height, equals(360));
      for (int y = 0; y < 360; y += 8) {
        for (int x = 0; x < 360; x += 12) {
          expect(
            i0.getPixel(x, y),
            equals(img.getPixel((x / 1.40625).toInt(), (y / 1.40625).toInt())),
            reason: 'Pixel color at ($x,$y) in resized image is not correct',
          );
        }
      }
      File('$testOutputPath/transform/copyResize_color_nearest_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize average larger color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 600,
        interpolation: Interpolation.average,
      ); // 256x256 => 600x600 = 2.34375 times each side
      expect(i0.width, equals(600));
      expect(i0.height, equals(600));
      for (int y = 0; y < 600; y += 12) {
        for (int x = 0; x < 600; x += 16) {
          expect(
            i0.getPixel(x, y),
            equals(img.getPixel((x / 2.34375).toInt(), (y / 2.34375).toInt())),
            reason: 'Pixel color at ($x,$y) in resized image is not correct',
          );
        }
      }
      File('$testOutputPath/transform/copyResize_color_average_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear smaller maintainAspect color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 128,
        height: 256,
        maintainAspect: true,
        backgroundColor: ColorUint8.fromList([253, 254, 252]),
        interpolation: Interpolation.linear,
      );
      expect(i0.width, equals(128));
      expect(i0.height, equals(256));

      //  Intended output, O is the resized original image, B is background:
      //  BBBBBBB
      //  BBBBBBB
      //  OOOOOOO
      //  OOOOOOO
      //  OOOOOOO
      //  OOOOOOO
      //  BBBBBBB
      //  BBBBBBB
      for (int y = 64; y < 64 + 128; y += 6) {
        for (int x = 0; x < 128; x += 6) {
          expect(
            i0.getPixel(x, y),
            equals(img.getPixel((x * 2).toInt(), ((y - 64) * 2).toInt())),
            reason: 'Pixel color at ($x,$y) in resized image is not correct',
          );
        }
      }

      // There should be empty space denoted by backgroundColor
      expect(i0.getPixel(0, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(
        i0.getPixel(127, 63),
        equals(ColorUint8.fromList([253, 254, 252])),
      );
      expect(
        i0.getPixel(0, 64 + 128),
        equals(ColorUint8.fromList([253, 254, 252])),
      );
      expect(
        i0.getPixel(127, 64 + 128),
        equals(ColorUint8.fromList([253, 254, 252])),
      );

      File(
        '$testOutputPath/transform/copyResize_color_linear_smaller_aspect_1.png',
      )
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear larger color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 272,
        interpolation: Interpolation.linear,
      );
      // 256x256 => 272x272 = 1.0625 times each side
      expect(i0.width, equals(272));
      expect(i0.height, equals(272));
      for (int y = 0; y < 272; y += 8) {
        for (int x = 0; x < 272; x += 12) {
          final out = i0.getPixel(x, y);
          final ori = img.getPixel((x / 1.0625).toInt(), (y / 1.0625).toInt());
          expect(
            out.r,
            closeTo(ori.r, 7),
            reason:
                'Pixel color red at ($x,$y) in resized image is not correct',
          );
          expect(
            out.g,
            closeTo(ori.g, 7),
            reason:
                'Pixelcolor green at($x,$y) in resized image is not correct',
          );
          expect(
            out.b,
            closeTo(ori.b, 7),
            reason: 'Pixelcolor blue at($x,$y) in resized image is not correct',
          );
        }
      }

      File('$testOutputPath/transform/copyResize_color_linear_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize cubic smaller maintainAspect color correctness', () {
      final img = decodeBmp(
        File('test/_data/bmp/rgba24.bmp').readAsBytesSync(),
      )!;
      final i0 = copyResize(
        img,
        width: 128,
        height: 256,
        maintainAspect: true,
        backgroundColor: ColorUint8.fromList([253, 254, 252]),
        interpolation: Interpolation.cubic,
      );
      expect(i0.width, equals(128));
      expect(i0.height, equals(256));

      //  Intended output, O is the resized original image, B is background:
      //  BBBBBBB
      //  BBBBBBB
      //  OOOOOOO
      //  OOOOOOO
      //  OOOOOOO
      //  OOOOOOO
      //  BBBBBBB
      //  BBBBBBB
      for (int y = 64; y < 64 + 128; y += 6) {
        for (int x = 0; x < 128; x += 6) {
          expect(
            i0.getPixel(x, y),
            equals(img.getPixel((x * 2).toInt(), ((y - 64) * 2).toInt())),
            reason: 'Pixel color at ($x,$y) in resized image is not correct',
          );
        }
      }

      // There should be empty space denoted by backgroundColor
      expect(i0.getPixel(0, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(
        i0.getPixel(127, 63),
        equals(ColorUint8.fromList([253, 254, 252])),
      );
      expect(
        i0.getPixel(0, 64 + 128),
        equals(ColorUint8.fromList([253, 254, 252])),
      );
      expect(
        i0.getPixel(127, 64 + 128),
        equals(ColorUint8.fromList([253, 254, 252])),
      );

      File(
        '$testOutputPath/transform/copyResize_color_cubic_smaller_aspect_1.png',
      )
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('cubic upscale of a solid image stays solid', () {
      // The tap above the center pixel used to read outside the image along
      // the top edge, darkening the first rows.
      final src = Image(width: 4, height: 4)..clear(ColorRgb8(200, 100, 50));
      final dst = copyResize(src,
          width: 16, height: 16, interpolation: Interpolation.cubic);
      for (final p in dst) {
        expect([p.r, p.g, p.b], equals([200, 100, 50]),
            reason: '${p.x},${p.y}');
      }
    });

    test('copyResize average weights color by alpha in mixed-alpha blocks', () {
      final source = Image(width: 4, height: 2, numChannels: 4);
      for (final pixel in source) {
        if (pixel.x.isEven) {
          pixel.setRgba(255, 0, 0, 255);
        } else {
          pixel.setRgba(255, 255, 0, 0);
        }
      }

      final resized =
          copyResize(source, width: 2, interpolation: Interpolation.average);

      expect(resized.toUint8List(), [255, 0, 0, 127, 255, 0, 0, 127]);
    });

    test('copyResize average weights gray by alpha in 2-channel image', () {
      final source = Image(width: 4, height: 2, numChannels: 2);
      source.toUint8List().setAll(0, [
        for (var pair = 0; pair < 4; pair++) ...[200, 255, 40, 0],
      ]);

      final resized =
          copyResize(source, width: 2, interpolation: Interpolation.average);

      expect(resized.toUint8List(), [200, 127, 200, 127]);
    });

    test('copyResize average weights color by alpha in uint16 image', () {
      final source =
          Image(width: 4, height: 2, format: Format.uint16, numChannels: 4);
      for (final pixel in source) {
        if (pixel.x.isEven) {
          pixel.setRgba(65535, 0, 0, 65535);
        } else {
          pixel.setRgba(65535, 65535, 0, 0);
        }
      }

      final resized =
          copyResize(source, width: 2, interpolation: Interpolation.average);

      for (final pixel in resized) {
        expect([pixel.r, pixel.g, pixel.b, pixel.a], [65535, 0, 0, 32767]);
      }
    });

    test('copyResize average weights color by alpha in 40000-pixel blocks', () {
      final source = Image(width: 400, height: 200, numChannels: 4);
      for (final pixel in source) {
        if (pixel.x % 8 == 0) {
          pixel.setRgba(255, 0, 255, 0);
        } else {
          pixel.setRgba(255, 255, 255, 255);
        }
      }

      final resized =
          copyResize(source, width: 2, interpolation: Interpolation.average);

      expect(resized.toUint8List(), [255, 255, 255, 223, 255, 255, 255, 223]);
    });

    test('copyResize average keeps unweighted mean in blocks of 1 alpha value',
        () {
      const alphas = [255, 128, 0, 77];
      final source = Image(width: 8, height: 2, numChannels: 4);
      for (final pixel in source) {
        pixel.setRgba(pixel.x * 31 + pixel.y * 7, 255 - pixel.x * 30,
            pixel.y * 200 + pixel.x, alphas[pixel.x ~/ 2]);
      }

      final resized =
          copyResize(source, width: 4, interpolation: Interpolation.average);

      final sourceBytes = source.toUint8List();
      final expected = <int>[];
      for (var block = 0; block < 4; block++) {
        for (var channel = 0; channel < 4; channel++) {
          var sum = 0;
          for (final column in [block * 2, block * 2 + 1]) {
            sum += sourceBytes[column * 4 + channel];
            sum += sourceBytes[(8 + column) * 4 + channel];
          }

          expected.add((sum * (1.0 / 4)).toInt());
        }
      }

      expect(resized.toUint8List(), expected);
    });

    test('copyResize average with EXIF orientation weights color by alpha', () {
      for (var orientation = 2; orientation <= 8; orientation++) {
        final source = Image(width: 8, height: 6, numChannels: 4);
        for (final pixel in source) {
          pixel.setRgba(pixel.x * 30, pixel.y * 40, 255 - pixel.x * 9,
              (pixel.x * 7 + pixel.y * 5) % 3 * 100);
        }
        source.exif.imageIfd.orientation = orientation;

        final width = orientation < 5 ? 4 : 3;
        final expected = copyResize(bakeOrientation(source),
            width: width, interpolation: Interpolation.average);
        final resized = copyResize(source,
            width: width, interpolation: Interpolation.average);

        expect(resized.toUint8List(), expected.toUint8List(),
            reason: 'orientation $orientation');
      }
    });

    for (final name in [
      'gif/animated.gif',
      'png/alpha_edge.png',
      'png/apng/test_apng1.png',
      'png/apng/test_apng3.png',
      'webp/animated_transparency.webp',
      'bmp/rgba32.bmp',
    ]) {
      test('copyResize average takes color from visible pixels of $name', () {
        final decoded = decodeTestImage(name);
        final source =
            decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;
        final resized = copyResize(source,
            width: 1 + source.width * 37 ~/ 100,
            interpolation: Interpolation.average);

        expect(hiddenColorPixels(source, resized), 0);
      });
    }

    for (final name in [
      'gif/animated.gif',
      'png/alpha_edge.png',
      'png/basi4a08.png',
      'png/basn6a08.png',
      'png/basn6a16.png',
      'png/apng/test_apng1.png',
      'png/buck_24.png',
    ]) {
      test('copyResize average matches alpha-weighted mean of $name', () {
        final decoded = decodeTestImage(name);
        final source =
            decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;

        for (final percent in [37, 50, 170]) {
          final width = 1 + source.width * percent ~/ 100;
          final resized = copyResize(source,
              width: width, interpolation: Interpolation.average);
          final expected =
              alphaWeightedAverage(source, resized.width, resized.height);

          expect(differingPixels(resized, expected), 0, reason: '$percent%');
        }
      });
    }

    for (final format in [Format.uint8, Format.uint16]) {
      test('copyResize average keeps solid ${format.name} color', () {
        final changed = <String>[];
        for (var block = 2; block <= 12; block++) {
          for (var value = 1; value <= 255; value++) {
            final source = Image(
                width: block * 2,
                height: block * 2,
                format: format,
                numChannels: 4);
            for (final pixel in source) {
              pixel.setRgba(value, value, value, value);
            }

            final resized = copyResize(source,
                width: 2, height: 2, interpolation: Interpolation.average);
            final pixel = resized.getPixel(1, 1);

            if (pixel.r != value || pixel.a != value) {
              changed.add('$value in ${block}x$block block');
            }
          }
        }

        expect(changed, isEmpty);
      });
    }

    for (final name in [
      'png/buck_24.png',
      'png/alpha_edge.png',
      'png/basn6a16.png',
      'png/basi4a08.png',
      'gif/animated.gif',
    ]) {
      test('resize average gives same pixels as copyResize for $name', () {
        final decoded = decodeTestImage(name);
        final source =
            decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;

        for (final percent in [13, 37, 50, 88]) {
          final width = 1 + source.width * percent ~/ 100;
          final copied = copyResize(source,
              width: width, interpolation: Interpolation.average);
          final inPlace = resize(source.clone(),
              width: width, interpolation: Interpolation.average);

          expect(differingPixels(inPlace, copied), 0, reason: '$percent%');
        }
      });
    }

    const blending = [
      Interpolation.linear,
      Interpolation.cubic,
      Interpolation.average,
    ];

    for (final name in [
      'gif/animated.gif',
      'png/alpha_edge.png',
      'png/basn6a16.png',
      'png/basi4a08.png',
      'png/apng/test_apng1.png',
      'bmp/rgba32.bmp',
    ]) {
      for (final interpolation in blending) {
        test(
            'color of transparent pixels of $name has no effect on '
            '${interpolation.name} copyResize and resize', () {
          final decoded = decodeTestImage(name);
          final source =
              decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;
          final changed = withHiddenColorChanged(source);

          for (final percent in [37, 50, 170]) {
            final width = 1 + source.width * percent ~/ 100;
            final copied =
                copyResize(source, width: width, interpolation: interpolation);
            final inPlace = resize(source.clone(),
                width: width, interpolation: interpolation);

            expect(
                visibleDifferences(
                    copyResize(changed,
                        width: width, interpolation: interpolation),
                    copied),
                0,
                reason: 'copyResize $percent%');
            expect(
                visibleDifferences(
                    resize(changed.clone(),
                        width: width, interpolation: interpolation),
                    inPlace),
                0,
                reason: 'resize $percent%');
            expect(differingPixels(inPlace, copied), 0,
                reason: 'resize against copyResize $percent%');
          }
        });
      }
    }

    for (final format in [Format.uint8, Format.uint16, Format.float32]) {
      for (final interpolation in blending) {
        test(
            '${interpolation.name} copyResize keeps solid ${format.name} '
            'color with mixed alpha', () {
          final source =
              Image(width: 13, height: 9, format: format, numChannels: 4);
          final opaque = source.maxChannelValue;
          final color = format == Format.float32 ? 0.25 : opaque ~/ 3;
          for (final pixel in source) {
            pixel.setRgba(color, color, color,
                (pixel.x * 5 + pixel.y * 3) % 4 == 0 ? 0 : opaque);
          }

          for (final width in [5, 13, 31]) {
            final resized =
                copyResize(source, width: width, interpolation: interpolation);

            for (final pixel in resized) {
              if (pixel.a > 0 && (pixel.r != color || pixel.b != color)) {
                fail('${pixel.r} at ${pixel.x},${pixel.y} of width $width');
              }
            }
          }
        });
      }
    }

    for (final entry in {
      Format.uint8: 200,
      Format.uint16: 40000,
      Format.float32: 0.5,
    }.entries) {
      test(
          'getPixelLinear and getPixelCubic of ${entry.key.name} image '
          'without alpha channel blend taps outside image as 0', () {
        final source = Image(width: 4, height: 4, format: entry.key);
        for (final pixel in source) {
          pixel.setRgb(entry.value, entry.value, entry.value);
        }

        final linear = source.getPixelLinear(-0.5, 1);
        final cubic = source.getPixelCubic(-0.5, 1);

        expect(linear.r, entry.value / 2);
        expect(cubic.r, entry.value / 2);
      });
    }

    test('linear copyResize gives color of only weighted tap exactly', () {
      final changed = <String>[];
      for (var color = 0; color < 256; color += 5) {
        for (var alpha = 1; alpha < 256; alpha += 7) {
          final source = Image(width: 2, height: 2, numChannels: 4)
            ..setPixelRgba(0, 0, 255 - color, 9, 9, 0)
            ..setPixelRgba(1, 0, 255 - color, 9, 9, 255)
            ..setPixelRgba(0, 1, color, color, color, alpha)
            ..setPixelRgba(1, 1, 255 - color, 9, 9, 0);

          for (final height in [3, 5, 7, 9, 13]) {
            final resized = copyResize(source,
                width: 2, height: height, interpolation: Interpolation.linear);

            for (var y = 0; y < height; y++) {
              final pixel = resized.getPixel(0, y);
              if (pixel.a > 0 && pixel.r != color) {
                changed.add('$color with alpha $alpha at row $y of $height');
              }
            }
          }
        }
      }

      expect(changed, isEmpty);
    });

    for (final format in [Format.uint16, Format.uint32]) {
      test('cubic copyResize of ${format.name} does not wrap overshoot', () {
        final source =
            Image(width: 4, height: 1, format: format, numChannels: 1);
        final highest = source.maxChannelValue;
        source
          ..setPixelRgb(0, 0, highest, 0, 0)
          ..setPixelRgb(1, 0, highest, 0, 0);

        final resized = copyResize(source,
            width: 9, height: 1, interpolation: Interpolation.cubic);
        final values = [for (final pixel in resized) pixel.r];

        expect(values.first, highest);
        expect(values.last, 0);
        for (var i = 1; i < values.length; i++) {
          expect(values[i], lessThanOrEqualTo(values[i - 1]),
              reason: '$values');
        }
      });
    }
  });
}
