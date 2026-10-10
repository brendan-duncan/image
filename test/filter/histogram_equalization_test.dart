import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('histogramEqualization_jpg1', () {
      final bytes = File('test/_data/jpg/oblique.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      final orig = i0.clone();
      histogramEqualization(i0);
      File('$testOutputPath/filter/histogramEqualization_jpg1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      // Grayscale mode replaces each pixel with its remapped luminance.
      _expectGray(i0);
      // The luminance distribution becomes close to uniform.
      _expectQuartiles(i0, 0, 255);
      expect(_cdfError(i0, 0, 255), lessThan(_cdfError(orig, 0, 255) / 3));
    });

    test('histogramEqualization_minmax', () {
      final bytes = File('test/_data/jpg/progress.jpg').readAsBytesSync();
      final i0 = decodeJpg(bytes)!;
      final orig = i0.clone();
      histogramEqualization(i0, outputRangeMin: 5, outputRangeMax: 220);
      File('$testOutputPath/filter/histogramEqualization_minmax.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));

      _expectGray(i0);
      // The output fills exactly [5, 220], evenly.
      final range = _channelRange(i0);
      expect(range.$1, equals(5));
      expect(range.$2, equals(220));
      _expectQuartiles(i0, 5, 220);
      expect(_cdfError(i0, 5, 220), lessThan(_cdfError(orig, 5, 220) / 3));
    });

    test('histogramEqualization Color', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      histogramEqualization(
        i0,
        mode: HistogramEqualizeMode.color,
        outputRangeMin: -20, // illegal values should take no effect
        outputRangeMax: 999,
      ); // illegal values should take no effect
      File('$testOutputPath/filter/histogramEqualization_color.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // The out-of-range limits are clamped to the full range.
      final range = _channelRange(i0);
      expect(range.$1, equals(0));
      expect(range.$2, equals(255));

      // Only HSL lightness is equalized: colors stay colored, and hues of
      // clearly saturated, unclipped pixels are kept.
      var gray = 0;
      var hueChecked = 0;
      for (final p in i0) {
        if (p.r == p.g && p.g == p.b) {
          gray++;
        }
        final o = orig.getPixel(p.x, p.y);
        final h0 = rgbToHsl(o.r, o.g, o.b);
        final h1 = rgbToHsl(p.r, p.g, p.b);
        if (h0[1] > 0.3 &&
            h1[1] > 0.3 &&
            h0[2] > 0.2 &&
            h0[2] < 0.8 &&
            h1[2] > 0.2 &&
            h1[2] < 0.8) {
          final d = (h0[0] - h1[0]).abs();
          expect(min(d, 1 - d), lessThan(0.03),
              reason: 'hue at ${p.x},${p.y}: $o -> $p');
          hueChecked++;
        }
      }
      expect(gray, lessThan(i0.width * i0.height * 0.1));
      expect(hueChecked, greaterThan(1000));

      // The lightness distribution becomes close to uniform.
      num lightness(Pixel p) => rgbToHsl(p.r, p.g, p.b)[2] * 255;
      _expectQuartiles(i0, 0, 255, value: lightness, tolerance: 0.02);
      expect(_cdfError(i0, 0, 255, value: lightness),
          lessThan(_cdfError(orig, 0, 255, value: lightness) / 3));
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
      final orig = decodePng(bytes)!;
      expect(orig.format, equals(Format.uint4));
      expect(orig.numChannels, equals(1));
      Image i0 = orig.clone();
      i0 = histogramEqualization(i0);

      File('$testOutputPath/filter/histogramEqualization_format3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // The image is expanded to 3 channels but keeps its bit depth.
      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.format, equals(Format.uint4));
      expect(i0.numChannels, equals(3));
      _expectGray(i0);
      final range = _channelRange(i0);
      expect(range.$1, equals(0));
      expect(range.$2, equals(15));

      // Each gray level maps to a single, non-decreasing output level, and
      // the levels are redistributed toward a uniform histogram.
      final levelMap = <num, num>{};
      for (final p in i0) {
        final v = orig.getPixel(p.x, p.y).r;
        expect(levelMap.putIfAbsent(v, () => p.r), equals(p.r),
            reason: 'level $v at ${p.x},${p.y}');
      }
      final levels = levelMap.keys.toList()..sort();
      for (var i = 1; i < levels.length; ++i) {
        expect(levelMap[levels[i]],
            greaterThanOrEqualTo(levelMap[levels[i - 1]]!));
      }
      expect(levels.any((l) => levelMap[l] != l), isTrue);
      num red(Pixel p) => p.r;
      expect(_cdfError(i0, 0, 15, value: red),
          lessThan(_cdfError(orig, 0, 15, value: red)));
    });

    test('histogramEqualization format4', () {
      // Color uint8 4 channel image
      final bytes = File('test/_data/tga/buck_32_rle.tga').readAsBytesSync();
      final orig = decodeTga(bytes)!;
      expect(orig.numChannels, equals(4));
      Image i0 = orig.clone();
      i0 = histogramEqualization(i0);

      File('$testOutputPath/filter/histogramEqualization_format4.tga')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeTga(i0));

      // The alpha channel is kept as is.
      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(4));
      for (final p in i0) {
        expect(p.a, equals(orig.getPixel(p.x, p.y).a));
      }
      _expectGray(i0);
      _expectQuartiles(i0, 0, 255);
      expect(_cdfError(i0, 0, 255), lessThan(_cdfError(orig, 0, 255) / 3));
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
      final orig = i0.clone();
      histogramStretch(i0);
      File('$testOutputPath/filter/histogramStretch_jpg1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      _expectGray(i0);
      // With the default clip ratio of 1.5%, about that many pixels at each
      // end are clipped to black and white.
      final n = i0.width * i0.height;
      var black = 0;
      var white = 0;
      for (final p in i0) {
        if (p.r == 0) {
          black++;
        } else if (p.r == 255) {
          white++;
        }
      }
      expect(black / n, inInclusiveRange(0.01, 0.04));
      expect(white / n, inInclusiveRange(0.01, 0.04));

      // The remapping is monotonic: brighter source pixels never end up
      // darker than dimmer ones.
      final pairs = [
        for (final p in i0) (orig.getPixel(p.x, p.y).luminance, p.r),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      for (var i = 1; i < pairs.length; ++i) {
        expect(pairs[i].$2, greaterThanOrEqualTo(pairs[i - 1].$2),
            reason: 'luminance ${pairs[i - 1].$1} -> ${pairs[i].$1}');
      }
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
      expect(H[220], greaterThan(0));

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

/// Expects every pixel of [image] to be gray (r == g == b).
void _expectGray(Image image) {
  for (final p in image) {
    expect(p.g, equals(p.r), reason: 'g at ${p.x},${p.y}');
    expect(p.b, equals(p.r), reason: 'b at ${p.x},${p.y}');
  }
}

/// The smallest and largest r, g or b value in [image].
(num, num) _channelRange(Image image) {
  num lo = image.maxChannelValue;
  num hi = 0;
  for (final p in image) {
    for (final v in [p.r, p.g, p.b]) {
      lo = min(lo, v);
      hi = max(hi, v);
    }
  }
  return (lo, hi);
}

num _luminance(Pixel p) => p.luminance;

/// The largest difference between the cumulative distribution of [value]
/// over [image] and that of a uniform distribution over [lo]..[hi].
double _cdfError(Image image, num lo, num hi,
    {num Function(Pixel) value = _luminance}) {
  final values = [for (final p in image) value(p)];
  var error = 0.0;
  for (var i = 1; i < 8; ++i) {
    final t = lo + (hi - lo) * i / 8;
    final below = values.where((v) => v < t).length / values.length;
    error = max(error, (below - i / 8).abs());
  }
  return error;
}

/// Expects a quarter, half and three quarters of the pixels to fall below
/// the respective quartiles of [lo]..[hi].
void _expectQuartiles(Image image, num lo, num hi,
    {num Function(Pixel) value = _luminance, double tolerance = 0.03}) {
  final n = image.width * image.height;
  for (final f in [0.25, 0.5, 0.75]) {
    final t = lo + (hi - lo) * f;
    var below = 0;
    for (final p in image) {
      if (value(p) < t) {
        below++;
      }
    }
    expect(below / n, closeTo(f, tolerance), reason: 'below $t');
  }
}
