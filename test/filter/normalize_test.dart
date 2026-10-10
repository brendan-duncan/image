import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('normalize', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      normalize(i0, min: 50, max: 150);
      File('$testOutputPath/filter/normalize.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      // Every channel is linearly mapped from the source [min, max] range to
      // [50, 150].
      final mM = minMax(orig);
      final mn = mM[0];
      final mx = mM[1];
      expect(mx, greaterThan(mn));
      num map(num v) => (v - mn) / (mx - mn) * 100 + 50;
      for (final p in i0) {
        final o = orig.getPixel(p.x, p.y);
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo(map(o[c]), 1),
              reason: 'channel $c at ${p.x},${p.y}');
        }
      }
      expect(minMax(i0), equals([50, 150]));
    });

    test('normalize preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = normalize(src.clone(), min: 50, max: 200);
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('normalize maps channel values to [min, max] range', () {
      // A horizontal gradient spans 0–255.  After normalize(min:50, max:150)
      // every channel value must lie within [50, 150].
      final src = horizontalGradient(32, 8);
      final out = normalize(src.clone(), min: 50, max: 150);
      for (final p in out) {
        expect(p.r, inInclusiveRange(49, 151),
            reason: 'r out of [50,150] at ${p.x},${p.y}');
        expect(p.g, inInclusiveRange(49, 151),
            reason: 'g out of [50,150] at ${p.x},${p.y}');
        expect(p.b, inInclusiveRange(49, 151),
            reason: 'b out of [50,150] at ${p.x},${p.y}');
      }
    });

    test('normalize: min channel value in result is near the target min', () {
      // After normalization the minimum channel value over the entire image
      // should be approximately equal to the requested min (50).
      final src = horizontalGradient(64, 8);
      final out = normalize(src.clone(), min: 50, max: 200);
      var minVal = double.infinity;
      for (final p in out) {
        if (p.r < minVal) minVal = p.r.toDouble();
        if (p.g < minVal) minVal = p.g.toDouble();
        if (p.b < minVal) minVal = p.b.toDouble();
      }
      expect(minVal, closeTo(50, 2));
    });

    test('normalize: max channel value in result is near the target max', () {
      // The maximum channel value should be approximately equal to max (200).
      final src = horizontalGradient(64, 8);
      final out = normalize(src.clone(), min: 50, max: 200);
      var maxVal = double.negativeInfinity;
      for (final p in out) {
        if (p.r > maxVal) maxVal = p.r.toDouble();
        if (p.g > maxVal) maxVal = p.g.toDouble();
        if (p.b > maxVal) maxVal = p.b.toDouble();
      }
      expect(maxVal, closeTo(200, 2));
    });

    test('normalize on a solid image is a no-op (all channels equal)', () {
      // The source short-circuits when mn == mx (all pixels identical).
      final src = solidImage(8, 8, ColorRgb8(100, 100, 100));
      testImageEquals(normalize(src.clone(), min: 0, max: 255), src);
    });

    test('normalize with all-zero mask leaves image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = normalize(
        src.clone(),
        min: 50,
        max: 200,
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
