import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('resize nearest', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = resize(img, width: 64);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/resize.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize average', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = resize(img, width: 64, interpolation: Interpolation.average);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/resize_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize linear', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = resize(img, width: 64, interpolation: Interpolation.linear);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/resize_linear.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize cubic', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = resize(img, width: 64, interpolation: Interpolation.cubic);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/resize_cubic.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize maintainAspect', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;
      final i0 = resize(
        img,
        width: 640,
        height: 640,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/resize_maintainAspect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize maintainAspect palette', () {
      final img = decodePng(
        File('test/_data/png/buck_8.png').readAsBytesSync(),
      )!;
      final i0 = resize(
        img,
        width: 640,
        height: 640,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/resize_maintainAspect_palette.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('resize maintainAspect 2', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = resize(
        i0,
        width: 200,
        height: 200,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/resize_maintainAspect_2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize maintainAspect 3', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = resize(
        i0,
        width: 200,
        height: 200,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/resize_maintainAspect_3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize maintainAspect 4', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = resize(
        i0,
        width: 50,
        height: 100,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(50));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/resize_maintainAspect_4.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = resize(
        i0,
        width: 100,
        height: 50,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(100));
      expect(i1.height, equals(50));
      File('$testOutputPath/transform/resize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = resize(
        i0,
        width: 100,
        height: 500,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(100));
      expect(i1.height, equals(500));
      File('$testOutputPath/transform/resize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize maintainAspect 6', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(0, 255, 0));
      final i1 = resize(
        i0,
        width: 500,
        height: 100,
        maintainAspect: true,
        backgroundColor: ColorRgb8(0, 0, 255),
      );
      expect(i1.width, equals(500));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/resize_maintainAspect_6.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('resize palette', () async {
      final img = await decodePngFile('test/_data/png/test.png');
      final i0 = resize(img!, width: 64, interpolation: Interpolation.cubic);
      await encodePngFile('$testOutputPath/transform/resize_palette.png', i0);
    });

    for (final interpolation in Interpolation.values) {
      test(
          'resize ${interpolation.name} with backgroundColor keeps pixels '
          'when maintainAspect adds no padding', () {
        final source = Image(width: 8, height: 4, numChannels: 4);
        for (final pixel in source) {
          pixel.setRgba(pixel.x * 30, pixel.y * 60, 200 - pixel.x * 20, 255);
        }

        final expected = copyResize(source,
            width: 4,
            height: 2,
            maintainAspect: true,
            backgroundColor: ColorRgba8(255, 0, 0, 255),
            interpolation: interpolation);
        final resized = resize(source.clone(),
            width: 4,
            height: 2,
            maintainAspect: true,
            backgroundColor: ColorRgba8(255, 0, 0, 255),
            interpolation: interpolation);

        expect(resized.toUint8List().sublist(0, 32), expected.toUint8List());
        expect(resized.getPixel(3, 1).b, isNot(0));
      });
    }

    for (final name in [
      'tiff/CNSW_crop.tif',
      'bmp/buck_24.bmp',
      'png/buck_8.png',
      'bmp/buck_4.bmp',
      'png/basn6a16.png',
    ]) {
      test('resize gives same pixels as copyResize for $name', () {
        final source = decodeTestImage(name);

        for (final interpolation in Interpolation.values) {
          for (final percent in [37, 50, 61]) {
            final width = 1 + source.width * percent ~/ 100;
            final copied =
                copyResize(source, width: width, interpolation: interpolation);
            final inPlace = resize(source.clone(),
                width: width, interpolation: interpolation);

            expect(differingPixels(inPlace, copied), 0,
                reason: '${interpolation.name} $percent%');
          }
        }
      });
    }

    test('pixel index of 16-bit palette image is palette index', () {
      final source = decodeTestImage('tiff/CNSW_crop.tif');
      expect(source.format, Format.uint16);
      expect(source.hasPalette, isTrue);

      final indices = source.data!.buffer.asUint16List();
      var mismatches = 0;
      for (final pixel in source) {
        final expected = indices[pixel.y * source.width + pixel.x];
        if (pixel.index != expected ||
            source.getPixelIndex(pixel.x, pixel.y) != expected ||
            pixel.r != source.palette!.getRed(expected)) {
          mismatches++;
        }
      }

      expect(mismatches, 0);
    });

    for (final format in [
      Format.uint8,
      Format.uint16,
      Format.float32,
      Format.uint4
    ]) {
      test('resize nearest of ${format.name} reads same pixels as copyResize',
          () {
        final mismatches = <String>[];
        for (var height = 2; height <= 40; height++) {
          final source = Image(width: height, height: height, format: format);
          for (final pixel in source) {
            pixel.setRgb(pixel.y % 16, pixel.y ~/ 16, pixel.x % 16);
          }

          for (var target = 1; target < height; target++) {
            final copied = copyResize(source, height: target);
            final inPlace = resize(source.clone(), height: target);
            if (differingPixels(inPlace, copied) != 0) {
              mismatches.add('$height to $target');
            }
          }
        }

        expect(mismatches, isEmpty);
      });
    }

    for (final format in [Format.uint8, Format.uint16]) {
      test('resize average weights ${format.name} color by alpha', () {
        final opaque = format == Format.uint8 ? 255 : 65535;
        final source =
            Image(width: 4, height: 2, format: format, numChannels: 4);
        for (final pixel in source) {
          if (pixel.x.isEven) {
            pixel.setRgba(opaque, 0, 0, opaque);
          } else {
            pixel.setRgba(opaque, opaque, 0, 0);
          }
        }

        final resized =
            resize(source, width: 2, interpolation: Interpolation.average);

        for (final pixel in resized) {
          expect([pixel.r, pixel.g, pixel.b, pixel.a],
              [opaque, 0, 0, opaque ~/ 2]);
        }
      });
    }

    for (final name in [
      'gif/animated.gif',
      'png/alpha_edge.png',
      'png/apng/test_apng1.png',
      'webp/animated_transparency.webp',
    ]) {
      test('resize average takes color from visible pixels of $name', () {
        final decoded = decodeTestImage(name);
        final source =
            decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;
        final resized = resize(source.clone(),
            width: 1 + source.width * 37 ~/ 100,
            interpolation: Interpolation.average);

        expect(hiddenColorPixels(source, resized), 0);
      });
    }

    for (final name in [
      'gif/animated.gif',
      'png/alpha_edge.png',
      'png/basi4a08.png',
      'png/basn6a16.png',
      'png/buck_24.png',
    ]) {
      test('resize average matches alpha-weighted mean of $name', () {
        final decoded = decodeTestImage(name);
        final source =
            decoded.hasPalette ? decoded.convert(numChannels: 4) : decoded;

        for (final percent in [37, 50]) {
          final resized = resize(source.clone(),
              width: 1 + source.width * percent ~/ 100,
              interpolation: Interpolation.average);
          final expected =
              alphaWeightedAverage(source, resized.width, resized.height);

          expect(differingPixels(resized, expected), 0, reason: '$percent%');
        }
      });
    }
  });
}
