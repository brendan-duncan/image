import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('emboss', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      emboss(i0);
      File('$testOutputPath/filter/emboss.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('emboss preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = emboss(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('emboss on a uniform image produces a flat (uniform) output', () {
      // The emboss kernel is [1.5, 0, 0, 0, 0, 0, 0, 0, -1.5] with offset=127.
      // For a uniform image every neighbourhood is the same constant C, so
      // each pixel becomes (1.5*C - 1.5*C)/1 + 127 = 127, clamped to [0,255].
      final src = solidImage(32, 32, ColorRgb8(100, 100, 100));
      final result = emboss(src.clone());
      // All pixels should have the same value (127).
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('emboss on a uniform image outputs ~127 per channel', () {
      // offset=127 and the kernel sum on uniform input is 0, so each channel
      // should be exactly 127.
      final src = solidImage(32, 32, ColorRgb8(200, 200, 200));
      final result = emboss(src.clone());
      final p = result.getPixel(16, 16);
      expect(p.r, equals(127));
      expect(p.g, equals(127));
      expect(p.b, equals(127));
    });

    test('emboss with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 means no blend → output equals original
      testImageEquals(emboss(src.clone(), amount: 0), src);
    });
  });
}
