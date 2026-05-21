import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('noise gaussian', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      noise(i0, 10);
      File('$testOutputPath/filter/noise_gaussian.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('noise uniform', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      noise(i0, 10, type: NoiseType.uniform);
      File('$testOutputPath/filter/noise_uniform.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('noise saltAndPepper', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      noise(i0, 10, type: NoiseType.saltAndPepper);
      File('$testOutputPath/filter/noise_saltAndPepper.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('noise poisson', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      noise(i0, 10, type: NoiseType.poisson);
      File('$testOutputPath/filter/noise_poisson.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('noise rice', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      noise(i0, 10, type: NoiseType.rice);
      File('$testOutputPath/filter/noise_rice.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
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
