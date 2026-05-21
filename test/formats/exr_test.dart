import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('exr', () {
      test('grid', () {
        final bytes = File('test/_data/exr/grid.exr').readAsBytesSync();

        final dec = ExrDecoder()..startDecode(bytes);
        final img = dec.decodeFrame(0)!;

        final png = PngEncoder().encode(img);
        File('$testOutputPath/exr/grid.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        // grid.exr is 512x512
        expect(img, isNotNull);
        expect(img.width, equals(512));
        expect(img.height, equals(512));
        // EXR is an HDR float format
        expect(img.format, equals(Format.float16));
        // 3-channel (RGB) image
        expect(img.numChannels, equals(3));
        // pixel data should be non-trivially non-zero
        expect(imageMean(img), greaterThan(0.0));
      });

      test('ocean', () {
        final bytes = File('test/_data/exr/ocean.exr').readAsBytesSync();

        final dec = ExrDecoder()..startDecode(bytes);
        final img = dec.decodeFrame(0)!;

        final png = PngEncoder().encode(img);
        File('$testOutputPath/exr/ocean.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        // ocean.exr is 300x209
        expect(img, isNotNull);
        expect(img.width, equals(300));
        expect(img.height, equals(209));
        // EXR is an HDR float format
        expect(img.format, equals(Format.float16));
        // 3-channel (RGB) image
        expect(img.numChannels, equals(3));
        // pixel data should be non-trivially non-zero
        expect(imageMean(img), greaterThan(0.0));
      });
    });
  });
}
