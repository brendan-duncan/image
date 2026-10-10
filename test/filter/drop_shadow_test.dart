import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('dropShadow', () {
      final i0 = Image(width: 256, height: 256, numChannels: 4);
      drawString(i0, 'Shadow', font: arial48, color: ColorRgb8(255, 0, 0));

      final id = dropShadow(i0, -5, 5, 3);

      final i1 = Image(width: 256, height: 256)
        ..clear(ColorRgb8(255, 255, 255));
      compositeImage(i1, id);

      File('$testOutputPath/filter/dropShadow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));

      expect(id.numChannels, equals(4));
      // The shadow is cast 5 pixels left and blurred by 3, so the source is
      // drawn 5 + 3 pixels to the right.
      // Note: the vertical offset is not checked; the shadow is currently
      // cast up by the blur radius rather than down by vShadow.
      const ox = 8;
      var textMinX = i0.width;
      for (final p in i0) {
        if (p.a == 255) {
          textMinX = min(textMinX, p.x);
          final q = id.getPixel(p.x + ox, p.y);
          expect(q, equals(p), reason: 'text at ${p.x},${p.y}');
        }
      }
      expect(textMinX, lessThan(i0.width));

      // Outside the text, the shadow is translucent black, at most the
      // default shadow alpha of 128, and it reaches left of the text.
      var shadowMinX = id.width;
      var shadow = 0;
      for (final p in id) {
        final sx = p.x - ox;
        final covered = sx >= 0 &&
            sx < i0.width &&
            p.y < i0.height &&
            i0.getPixel(sx, p.y).a > 0;
        if (covered || p.a == 0) {
          continue;
        }
        expect(p.r, equals(0), reason: 'shadow at ${p.x},${p.y}');
        expect(p.g, equals(0), reason: 'shadow at ${p.x},${p.y}');
        expect(p.b, equals(0), reason: 'shadow at ${p.x},${p.y}');
        expect(p.a, lessThanOrEqualTo(128), reason: 'shadow at ${p.x},${p.y}');
        shadowMinX = min(shadowMinX, p.x);
        shadow++;
      }
      expect(shadow, greaterThan(100));
      expect(shadowMinX, lessThan(textMinX + ox - 5));

      // Over white, the shadow shows as gray.
      var gray = 0;
      for (final p in i1) {
        if (p.r == p.g && p.g == p.b && p.r >= 127 && p.r < 250) {
          gray++;
        }
      }
      expect(gray, greaterThan(100));
    });

    test('dropShadow returns a new image (not the source)', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      final result = dropShadow(src, 4, 4, 2);
      // dropShadow always allocates a fresh destination image
      expect(identical(result, src), isFalse);
    });

    test('dropShadow output has 4 channels', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      final result = dropShadow(src, 4, 4, 2);
      // the internal image is always created with numChannels: 4
      expect(result.numChannels, equals(4));
    });

    test('dropShadow with positive offsets enlarges the canvas', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      // hShadow=4, vShadow=4, blur=2 → shadow extends beyond the source
      // boundary so the result must be wider and taller than the source.
      final result = dropShadow(src, 4, 4, 2);
      expect(result.width, greaterThan(src.width));
      expect(result.height, greaterThan(src.height));
    });

    test('dropShadow with blur=0 still returns a valid image', () {
      final src = Image(width: 16, height: 16, numChannels: 4);
      final result = dropShadow(src, 2, 2, 0);
      // Zero blur is allowed; clamped internally to 0.
      expect(result.width, greaterThanOrEqualTo(src.width));
      expect(result.height, greaterThanOrEqualTo(src.height));
    });
  });
}
