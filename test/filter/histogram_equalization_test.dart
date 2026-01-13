import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('histogramEqualization_jpg1', () {
      final bytes = File('test/_data/jpg/oblique.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      histogramEqualization(i0);
      File('$testOutputPath/filter/histogramEqualization_jpg1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));
    });

    test('histogramEqualization_minmax', () {
      final bytes = File('test/_data/jpg/progress.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      histogramEqualization(i0, outputRangeMin: 5, outputRangeMax: 220);
      File('$testOutputPath/filter/histogramEqualization_minmax.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));
    });

    test('histogramEqualization Color', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      histogramEqualization(
        i0,
        mode: HistogramEqualizeMode.color,
        outputRangeMin: -20, // illegal values should take no effect
        outputRangeMax: 999,
      ); // illegal values should take no effect
      File('$testOutputPath/filter/histogramEqualization_color.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('histogramEqualization synthetic1', () {
      final i0 = Image(width: 64, height: 5)..clear(ColorRgb8(0, 0, 0));
      for (final (v, p) in i0.frames[0].indexed) {
        p.setRgb((v % 64) * 2, (v % 64) * 2, (v % 64) * 2);
      }
      histogramEqualization(i0);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      int pCounter = 0;
      for (int l = 0; l < 128; ++l) {
        pCounter += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounter / numOfPixel, lessThan(0.5001));
      expect(pCounter / numOfPixel, greaterThanOrEqualTo(0.4999));

      File('$testOutputPath/filter/histogramEqualization_synthetic1.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(i0));
    });

    test('histogramEqualization synthetic2', () {
      final i0 = Image(width: 729, height: 1)..clear(ColorRgb8(0, 0, 0));
      for (final (v, p) in i0.frames[0].indexed) {
        p.setRgb(v / 3 + 6, v / 5 + 8, v / 7 + 22);
      }
      histogramEqualization(i0, outputRangeMin: 5, outputRangeMax: 250);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      int pCounterLow = 0;
      for (int l = 0; l < 128; ++l) {
        pCounterLow += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounterLow / numOfPixel, lessThan(0.51));
      expect(pCounterLow / numOfPixel, greaterThanOrEqualTo(0.49));

      // Verify no pixel count beyond output min max
      for (int l = 0; l < 5; ++l) {
        expect(H[l], equals(0));
      }
      for (int l = 251; l < 256; ++l) {
        expect(H[l], equals(0));
      }

      File('$testOutputPath/filter/histogramEqualization_synthetic2.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(i0));
    });

    test('histogramEqualization synthetic3', () {
      final i0 = Image(width: 1024, height: 1)..clear(ColorRgb8(0, 0, 0));
      for (final (v, p) in i0.frames[0].indexed) {
        p.setRgb(v / 4, v / 4, v / 4);
      }
      histogramEqualization(i0);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      int pCounter = 0;
      for (int l = 0; l < 128; ++l) {
        pCounter += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounter / numOfPixel, lessThan(0.5001));
      expect(pCounter / numOfPixel, greaterThanOrEqualTo(0.4999));

      int pCounterK = 0;
      for (int l = 120; l < 120 + 96; l += 3) {
        pCounterK += H[l].floor();
      }
      // Any 32 bin (out of 256) should make up 12.5% of the pixels
      expect(pCounterK / numOfPixel, lessThan(0.126));
      expect(pCounterK / numOfPixel, greaterThanOrEqualTo(0.124));

      File('$testOutputPath/filter/histogramEqualization_synthetic3.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(i0));
    });

    test('histogramEqualization format1', () {
      // Test concerns the computation of luminance in single channel image
      final bytes = File('test/_data/png/basn0g04.png').readAsBytesSync();
      Image i0 = decodePng(bytes)!;
      i0 = histogramEqualization(i0);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      int pCounter = 0;
      for (int l = 0; l < 8; ++l) {
        pCounter += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounter / numOfPixel, lessThan(0.57));
      expect(pCounter / numOfPixel, greaterThanOrEqualTo(0.43));

      File('$testOutputPath/filter/histogramEqualization_format1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('histogramEqualization format2', () {
      final bytes = File('test/_data/png/david.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      histogramEqualization(i0, mode: HistogramEqualizeMode.color);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      int pCounter = 0;
      for (int l = 0; l < 128; ++l) {
        pCounter += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounter / numOfPixel, lessThan(0.51));
      expect(pCounter / numOfPixel, greaterThanOrEqualTo(0.49));

      File('$testOutputPath/filter/histogramEqualization_format2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('histogramEqualization format3', () {
      // Grayscale uint4 single channel image
      final bytes = File('test/_data/png/cten0g04.png').readAsBytesSync();
      Image i0 = decodePng(bytes)!;
      i0 = histogramEqualization(i0);

      File('$testOutputPath/filter/histogramEqualization_format3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('histogramEqualization format4', () {
      // Color uint8 4 channel image
      final bytes = File('test/_data/tga/buck_32_rle.tga').readAsBytesSync();
      Image i0 = decodeTga(bytes)!;
      i0 = histogramEqualization(i0);

      File('$testOutputPath/filter/histogramEqualization_format4.tga')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeTga(i0));
    });

    test('histogramEqualization format5', () {
      // Animated gif (30 frames)
      final bytes = File('test/_data/gif/cars.gif').readAsBytesSync();
      Image i0 = decodeGif(bytes)!;
      i0 = histogramEqualization(i0, mode: HistogramEqualizeMode.color);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[15]) {
        H[p.luminance.round()]++;
      }

      int pCounter = 0;
      for (int l = 0; l < 128; ++l) {
        pCounter += H[l].floor();
      }

      // First half of histogram should make up half of the pixels
      final numOfPixel = i0.width * i0.height;
      expect(pCounter / numOfPixel, lessThan(0.55));
      expect(pCounter / numOfPixel, greaterThanOrEqualTo(0.45));

      File('$testOutputPath/filter/histogramEqualization_format5.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeGif(i0));
    });

    test('histogramEqualization format6', () {
      // Known issue: Palette convertion eliminates transparency of pixels
      // An egg bouncing in a transparent background
      final bytes = File('test/_data/gif/bounce.gif').readAsBytesSync();
      Image i0 = decodeGif(bytes)!;
      i0 = histogramEqualization(i0);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      num validPixelCounts = 0;
      for (final p in i0.frames[15]) {
        if ((i0.hasAlpha) && (p.a == 0)) {
          continue;
        }
        H[p.luminance.round()]++;
        validPixelCounts++;
      }

      int pCounter = 0;
      for (int l = 0; l < 128; ++l) {
        pCounter += H[l].floor();
      }

      // Dark pixels make up a small portion of the image
      expect(pCounter / validPixelCounts, lessThan(0.51));
      expect(pCounter / validPixelCounts, greaterThanOrEqualTo(0.49));

      File('$testOutputPath/filter/histogramEqualization_format6.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeGif(i0));
    });

    test('histogramStretch_jpg1', () {
      final bytes = File('test/_data/jpg/oblique.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      histogramStretch(i0);
      File('$testOutputPath/filter/histogramStretch_jpg1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));
    });

    test('histogramStretch_minmax', () {
      final bytes = File('test/_data/jpg/progress.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      histogramStretch(i0, outputRangeMin: 5, outputRangeMax: 220);

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      // Verify no pixel count beyond output min max
      for (int l = 0; l < 5; ++l) {
        expect(H[l], equals(0));
      }
      for (int l = 221; l < 256; ++l) {
        expect(H[l], equals(0));
      }

      File('$testOutputPath/filter/histogramStretch_minmax.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));
    });

    test('histogramStretch Color', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      Image i0 = decodePng(bytes)!;
      i0 = histogramStretch(
        i0,
        mode: HistogramEqualizeMode.color,
        stretchClipRatio: 0.06,
      );

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      for (final p in i0.frames[0]) {
        H[p.luminance.round()]++;
      }

      // Clip ratio of 0.06, there should be around 6% of pixel counts
      // in each of the two ends of the output histogram
      final numOfPixel = i0.width * i0.height;
      expect(H[0] / numOfPixel, lessThan(0.067));
      expect(H[0] / numOfPixel, greaterThanOrEqualTo(0.059));
      expect(H.last / numOfPixel, lessThan(0.067));
      expect(H.last / numOfPixel, greaterThanOrEqualTo(0.059));

      File('$testOutputPath/filter/histogramStretch_color.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('histogramStretch format1', () {
      // Known issue: Palette convertion eliminates transparency of pixels
      // An egg bouncing in a transparent background
      final bytes = File('test/_data/gif/bounce.gif').readAsBytesSync();
      Image i0 = decodeGif(bytes)!;
      i0 = histogramStretch(
        i0,
        mode: HistogramEqualizeMode.color,
        outputRangeMax: 200,
      );

      // Take histogram
      final List<num> H = List<num>.generate(
        i0.maxChannelValue.ceil() + 1,
        (_) => 0,
        growable: false,
      );
      num validPixelCounts = 0;
      for (final p in i0.frames[15]) {
        if ((i0.hasAlpha) && (p.a == 0)) {
          continue;
        }
        H[p.luminance.round()]++;
        validPixelCounts++;
      }

      int pCounter = 0;
      for (int l = 0; l < 100; ++l) {
        pCounter += H[l].floor();
      }

      // Dark pixels make up a small portion of the image
      expect(pCounter / validPixelCounts, lessThan(0.30));
      expect(pCounter / validPixelCounts, greaterThanOrEqualTo(0.20));

      File('$testOutputPath/filter/histogramStretch_format1.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeGif(i0));
    });
  });
}
