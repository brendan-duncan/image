import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyResize nearest', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      final i0 = copyResize(img, width: 64);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize average', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      final i0 =
          copyResize(img, width: 64, interpolation: Interpolation.average);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      final i0 =
          copyResize(img, width: 64, interpolation: Interpolation.linear);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_linear.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize cubic', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      final i0 = copyResize(img, width: 64, interpolation: Interpolation.cubic);
      expect(i0.width, equals(64));
      expect(i0.height, equals(40));
      File('$testOutputPath/transform/copyResize_cubic.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 640,
          height: 640,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/copyResize_maintainAspect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect palette', () {
      final img =
          decodePng(File('test/_data/png/buck_8.png').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 640,
          height: 640,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i0.width, equals(640));
      expect(i0.height, equals(640));
      File('$testOutputPath/transform/copyResize_maintainAspect_palette.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize maintainAspect 2', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = copyResize(i0,
          width: 200,
          height: 200,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/copyResize_maintainAspect_2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 3', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(i0,
          width: 200,
          height: 200,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(200));
      expect(i1.height, equals(200));
      File('$testOutputPath/transform/copyResize_maintainAspect_3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 4', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(255, 0, 0));
      final i1 = copyResize(i0,
          width: 50,
          height: 100,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(50));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/copyResize_maintainAspect_4.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(i0,
          width: 100,
          height: 50,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(100));
      expect(i1.height, equals(50));
      File('$testOutputPath/transform/copyResize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 5', () {
      final i0 = Image(width: 50, height: 100)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(i0,
          width: 100,
          height: 500,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(100));
      expect(i1.height, equals(500));
      File('$testOutputPath/transform/copyResize_maintainAspect_5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize maintainAspect 6', () {
      final i0 = Image(width: 100, height: 50)..clear(ColorRgb8(0, 255, 0));
      final i1 = copyResize(i0,
          width: 500,
          height: 100,
          maintainAspect: true,
          backgroundColor: ColorRgb8(0, 0, 255));
      expect(i1.width, equals(500));
      expect(i1.height, equals(100));
      File('$testOutputPath/transform/copyResize_maintainAspect_6.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('copyResize palette', () async {
      final img = await decodePngFile('test/_data/png/test.png');
      final i0 =
          copyResize(img!, width: 64, interpolation: Interpolation.cubic);
      await encodePngFile(
          '$testOutputPath/transform/copyResize_palette.png', i0);
    });

    test('copyResize nearest smaller color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 = copyResize(img, width: 64); // 256x256 => 64x64
      expect(i0.width, equals(64));
      expect(i0.height, equals(64));
      for (int y = 0; y < 64; y += 6) {
        for (int x = 0; x < 64; x += 8) {
          expect(i0.getPixel(x, y), equals(img.getPixel(x * 4, y * 4)),
              reason: 'Pixel color at ($x,$y) in resized image is not correct');
        }
      }
      File('$testOutputPath/transform/copyResize_color_nearest_smaller_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize nearest larger color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 360); // 256x256 => 360x360 = 1.40625 times each side
      expect(i0.width, equals(360));
      expect(i0.height, equals(360));
      for (int y = 0; y < 360; y += 8) {
        for (int x = 0; x < 360; x += 12) {
          expect(
              i0.getPixel(x, y),
              equals(
                  img.getPixel((x / 1.40625).toInt(), (y / 1.40625).toInt())),
              reason: 'Pixel color at ($x,$y) in resized image is not correct');
        }
      }
      File('$testOutputPath/transform/copyResize_color_nearest_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize average larger color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 600,
          interpolation: Interpolation
              .average); // 256x256 => 600x600 = 2.34375 times each side
      expect(i0.width, equals(600));
      expect(i0.height, equals(600));
      for (int y = 0; y < 600; y += 12) {
        for (int x = 0; x < 600; x += 16) {
          expect(
              i0.getPixel(x, y),
              equals(
                  img.getPixel((x / 2.34375).toInt(), (y / 2.34375).toInt())),
              reason: 'Pixel color at ($x,$y) in resized image is not correct');
        }
      }
      File('$testOutputPath/transform/copyResize_color_average_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear smaller maintainAspect color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 128,
          height: 256,
          maintainAspect: true,
          backgroundColor: ColorUint8.fromList([253, 254, 252]),
          interpolation: Interpolation.linear);
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
          expect(i0.getPixel(x, y),
              equals(img.getPixel((x * 2).toInt(), ((y - 64) * 2).toInt())),
              reason: 'Pixel color at ($x,$y) in resized image is not correct');
        }
      }

      // There should be empty space denoted by backgroundColor
      expect(i0.getPixel(0, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(
          i0.getPixel(127, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(i0.getPixel(0, 64 + 128),
          equals(ColorUint8.fromList([253, 254, 252])));
      expect(i0.getPixel(127, 64 + 128),
          equals(ColorUint8.fromList([253, 254, 252])));

      File(
          '$testOutputPath/transform/copyResize_color_linear_smaller_aspect_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize linear larger color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 =
          copyResize(img, width: 272, interpolation: Interpolation.linear);
      // 256x256 => 272x272 = 1.0625 times each side
      expect(i0.width, equals(272));
      expect(i0.height, equals(272));
      for (int y = 0; y < 272; y += 8) {
        for (int x = 0; x < 272; x += 12) {
          final out = i0.getPixel(x, y);
          final ori = img.getPixel((x / 1.0625).toInt(), (y / 1.0625).toInt());
          expect(out.r, closeTo(ori.r, 7),
              reason:
                  'Pixel color red at ($x,$y) in resized image is not correct');
          expect(out.g, closeTo(ori.g, 7),
              reason:
                  'Pixel color green at ($x,$y) in resized image is not correct');
          expect(out.b, closeTo(ori.b, 7),
              reason:
                  'Pixel color blue at ($x,$y) in resized image is not correct');
        }
      }

      File('$testOutputPath/transform/copyResize_color_linear_larger_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyResize cubic smaller maintainAspect color correctness', () {
      final img =
          decodeBmp(File('test/_data/bmp/rgba24.bmp').readAsBytesSync())!;
      final i0 = copyResize(img,
          width: 128,
          height: 256,
          maintainAspect: true,
          backgroundColor: ColorUint8.fromList([253, 254, 252]),
          interpolation: Interpolation.cubic);
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
          expect(i0.getPixel(x, y),
              equals(img.getPixel((x * 2).toInt(), ((y - 64) * 2).toInt())),
              reason: 'Pixel color at ($x,$y) in resized image is not correct');
        }
      }

      // There should be empty space denoted by backgroundColor
      expect(i0.getPixel(0, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(
          i0.getPixel(127, 63), equals(ColorUint8.fromList([253, 254, 252])));
      expect(i0.getPixel(0, 64 + 128),
          equals(ColorUint8.fromList([253, 254, 252])));
      expect(i0.getPixel(127, 64 + 128),
          equals(ColorUint8.fromList([253, 254, 252])));

      File(
          '$testOutputPath/transform/copyResize_color_cubic_smaller_aspect_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
