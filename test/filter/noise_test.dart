import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Statistics of the per-channel (r, g, b) differences `out - orig`,
/// optionally restricted to original channel values in [minOrig, maxOrig].
class _NoiseDiff {
  var count = 0;
  num sum = 0;
  num sumSq = 0;
  num maxAbs = 0;
  var changedPixels = 0;
  var pixels = 0;

  _NoiseDiff(Image orig, Image out, {num minOrig = 0, num maxOrig = 255}) {
    for (final p in out) {
      final o = orig.getPixel(p.x, p.y);
      pixels++;
      if (p.r != o.r || p.g != o.g || p.b != o.b) {
        changedPixels++;
      }
      for (var c = 0; c < 3; ++c) {
        if (o[c] < minOrig || o[c] > maxOrig) {
          continue;
        }
        final d = p[c] - o[c];
        count++;
        sum += d;
        sumSq += d * d;
        if (d.abs() > maxAbs) {
          maxAbs = d.abs();
        }
      }
    }
  }

  double get mean => sum / count;
  double get rms => sqrt(sumSq / count);
  double get changedFraction => changedPixels / pixels;
}

void main() {
  group('Filter', () {
    test('noise gaussian', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      noise(i0, 10);
      File('$testOutputPath/filter/noise_gaussian.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final d = _NoiseDiff(orig, i0);
      // Gaussian noise with sigma 10 perturbs nearly every pixel, with a
      // zero-mean, standard deviation ~10 difference.
      expect(d.changedFraction, greaterThan(0.95));
      expect(d.mean.abs(), lessThan(1.5));
      expect(d.rms, inInclusiveRange(9, 11));
      expect(d.maxAbs, lessThan(80));
    });

    test('noise uniform', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      noise(i0, 10, type: NoiseType.uniform);
      File('$testOutputPath/filter/noise_uniform.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final d = _NoiseDiff(orig, i0);
      // Uniform noise in [-10, 10] has a standard deviation of 10/sqrt(3) and
      // never moves a channel by more than 10.
      expect(d.changedFraction, greaterThan(0.95));
      expect(d.mean.abs(), lessThan(1.5));
      expect(d.rms, inInclusiveRange(5, 6.5));
      expect(d.maxAbs, lessThanOrEqualTo(10));
    });

    test('noise saltAndPepper', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      noise(i0, 10, type: NoiseType.saltAndPepper);
      File('$testOutputPath/filter/noise_saltAndPepper.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final d = _NoiseDiff(orig, i0);
      // About 10% of the pixels are set to the image's min or max value
      // (0 or 255 here); every other pixel is left untouched.
      final mM = minMax(orig);
      expect(mM, equals([0, 255]));
      var salt = 0;
      var pepper = 0;
      for (final p in i0) {
        final o = orig.getPixel(p.x, p.y);
        if (p == o) {
          continue;
        }
        if (p.r == 255 && p.g == 255 && p.b == 255) {
          salt++;
        } else if (p.r == 0 && p.g == 0 && p.b == 0) {
          pepper++;
        } else {
          fail('pixel ${p.x},${p.y} changed from ($o) to ($p)');
        }
      }
      expect(d.changedFraction, inInclusiveRange(0.08, 0.12));
      expect(salt, greaterThan(0));
      expect(pepper, greaterThan(0));
    });

    test('noise poisson', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      noise(i0, 10, type: NoiseType.poisson);
      File('$testOutputPath/filter/noise_poisson.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final d = _NoiseDiff(orig, i0);
      // Poisson noise has a variance equal to the channel value, so the mean
      // squared difference is close to the mean channel value.
      final m = imageMean(orig);
      expect(d.changedFraction, greaterThan(0.95));
      expect(d.mean.abs(), lessThan(1.5));
      expect(d.rms * d.rms, inInclusiveRange(m * 0.8, m * 1.2));
    });

    test('noise rice', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      noise(i0, 10, type: NoiseType.rice);
      File('$testOutputPath/filter/noise_rice.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final d = _NoiseDiff(orig, i0);
      // Rice noise is the magnitude of a noisy vector: nearly zero-mean on
      // bright values, but it always brightens near-black values.
      final dark = _NoiseDiff(orig, i0, maxOrig: 9);
      final bright = _NoiseDiff(orig, i0, minOrig: 100);
      expect(d.changedFraction, greaterThan(0.95));
      expect(d.rms, inInclusiveRange(8.5, 11));
      expect(bright.mean.abs(), lessThan(1.5));
      expect(dark.count, greaterThan(100));
      expect(dark.mean, greaterThan(4));
    });

    test('noise preserves image dimensions', () {
      final src = solidImage(32, 24, ColorRgb8(128, 128, 128));
      noise(src, 20);
      // Noise must not resize the image.
      expect(src.width, equals(32));
      expect(src.height, equals(24));
    });

    test('noise returns the image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 100, 100));
      final result = noise(src, 10);
      expect(identical(result, src), isTrue);
    });

    test('noise actually changes pixels (gaussian)', () {
      // With a large sigma noise must perturb at least some pixels.
      final src = solidImage(32, 32, ColorRgb8(128, 128, 128));
      final orig = src.clone();
      noise(src, 50);
      var changed = 0;
      for (final p in src) {
        final o = orig.getPixel(p.x, p.y);
        if (p.r != o.r || p.g != o.g || p.b != o.b) changed++;
      }
      expect(changed, greaterThan(0),
          reason: 'gaussian noise did not change any pixel');
    });

    test('noise keeps channel values in valid range (gaussian)', () {
      // Channels must be clamped to [0, maxChannelValue].
      final src = solidImage(32, 32, ColorRgb8(128, 128, 128));
      noise(src, 200);
      for (final p in src) {
        expect(p.r, greaterThanOrEqualTo(0));
        expect(p.r, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.g, greaterThanOrEqualTo(0));
        expect(p.g, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.b, greaterThanOrEqualTo(0));
        expect(p.b, lessThanOrEqualTo(p.maxChannelValue));
      }
    });

    test('noise sigma 0 is a no-op', () {
      // The source returns early when sigma==0 (non-poisson types).
      final src = horizontalGradient(32, 16);
      final orig = src.clone();
      noise(src, 0);
      testImageEquals(src, orig);
    });

    for (final type in NoiseType.values) {
      test('noise $type keeps channel values in valid range', () {
        final src = solidImage(16, 16, ColorRgb8(128, 128, 128));
        noise(src, 100, type: type);
        for (final p in src) {
          expect(p.r, greaterThanOrEqualTo(0),
              reason: '$type r<0 at ${p.x},${p.y}');
          expect(p.r, lessThanOrEqualTo(p.maxChannelValue),
              reason: '$type r>max at ${p.x},${p.y}');
          expect(p.g, greaterThanOrEqualTo(0),
              reason: '$type g<0 at ${p.x},${p.y}');
          expect(p.g, lessThanOrEqualTo(p.maxChannelValue),
              reason: '$type g>max at ${p.x},${p.y}');
          expect(p.b, greaterThanOrEqualTo(0),
              reason: '$type b<0 at ${p.x},${p.y}');
          expect(p.b, lessThanOrEqualTo(p.maxChannelValue),
              reason: '$type b>max at ${p.x},${p.y}');
        }
      });
    }
  });
}
