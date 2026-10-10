import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('bumpToNormal', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final i1 = bumpToNormal(i0);
      File('$testOutputPath/filter/bumpToNormal.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));

      expect(i1.width, equals(i0.width));
      expect(i1.height, equals(i0.height));

      // The red channel is the height. Where it rises to the right (or
      // downward) the normal tilts away, below the flat value 0.5; where it
      // falls the normal tilts above it; where it is level it is exactly flat.
      // Blue (z) is only at its maximum where both slopes are 0.
      final flat = i1.maxChannelValue * 0.5;
      for (final p in i1) {
        final x = p.x;
        final y = p.y;
        final h = i0.getPixel(x, y).r;
        final hr = i0.getPixel(min(x + 1, i0.width - 1), y).r;
        final hd = i0.getPixel(x, min(y + 1, i0.height - 1)).r;
        final at = 'at $x,$y';
        if (hr > h) {
          expect(p.r, lessThan(flat - 0.5), reason: 'r $at');
        } else if (hr < h) {
          expect(p.r, greaterThan(flat), reason: 'r $at');
        } else {
          expect(p.r, inInclusiveRange(flat - 0.5, flat), reason: 'r $at');
        }
        if (hd > h) {
          expect(p.g, lessThan(flat - 0.5), reason: 'g $at');
        } else if (hd < h) {
          expect(p.g, greaterThan(flat), reason: 'g $at');
        } else {
          expect(p.g, inInclusiveRange(flat - 0.5, flat), reason: 'g $at');
        }
        if (hr == h && hd == h) {
          expect(p.b, equals(i1.maxChannelValue), reason: 'b $at');
        } else {
          expect(p.b, lessThan(i1.maxChannelValue), reason: 'b $at');
        }
      }
    });

    test('bumpToNormal preserves dimensions', () {
      final src = solidImage(64, 48, ColorRgb8(128, 128, 128));
      final result = bumpToNormal(src);
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('bumpToNormal returns a new image (not the source)', () {
      final src = solidImage(16, 16, ColorRgb8(100, 100, 100));
      final result = bumpToNormal(src);
      // bumpToNormal always allocates a fresh destination image
      expect(identical(result, src), isFalse);
    });

    test('bumpToNormal on a flat image produces a uniform normal map', () {
      // A completely flat heightfield (uniform red channel) has zero
      // horizontal/vertical gradients: du = 0, dv = 0.
      // That gives nX = 0.5, nY = 0.5, nZ = 1.0 → RGB = (127, 127, 255) in
      // uint8 (0.5*255 = 127.5 rounds, 1.0*255 = 255).
      final src = solidImage(32, 32, ColorRgb8(128, 128, 128));
      final result = bumpToNormal(src);
      // Every interior pixel must have the same color.
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('bumpToNormal flat normal points up (blue channel dominant)', () {
      // For a flat surface du=0, dv=0 → nZ = sqrt(1-0-0) = 1.0 → b = 255.
      // nX = nY = 0.5 → r = g ≈ 127.
      final src = solidImage(16, 16, ColorRgb8(200, 200, 200));
      final result = bumpToNormal(src);
      final p = result.getPixel(0, 0);
      // Blue channel should be the largest (pointing up).
      expect(p.b, greaterThan(p.r),
          reason: 'blue should dominate for a flat surface');
      expect(p.b, greaterThan(p.g),
          reason: 'blue should dominate for a flat surface');
    });

    test('bumpToNormal output pixel values are in valid range', () {
      final src = horizontalGradient(32, 32);
      final result = bumpToNormal(src);
      for (final p in result) {
        expect(p.r, inInclusiveRange(0, p.maxChannelValue),
            reason: 'r out of range at ${p.x},${p.y}');
        expect(p.g, inInclusiveRange(0, p.maxChannelValue),
            reason: 'g out of range at ${p.x},${p.y}');
        expect(p.b, inInclusiveRange(0, p.maxChannelValue),
            reason: 'b out of range at ${p.x},${p.y}');
      }
    });
  });
}
