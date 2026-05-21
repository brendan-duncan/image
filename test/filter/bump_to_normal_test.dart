import 'dart:io';
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
      // Every interior pixel must have the same colour.
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
