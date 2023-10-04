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
  });
}
