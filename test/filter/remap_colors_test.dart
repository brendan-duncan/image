import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('remapColors', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      remapColors(
        i0,
        red: Channel.green,
        green: Channel.luminance,
        blue: Channel.red,
      );
      File('$testOutputPath/filter/remapColors.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));
      // red <- green, green <- luminance, blue <- red.
      for (final p in i0) {
        final o = orig.getPixel(p.x, p.y);
        final l = 0.299 * o.r + 0.587 * o.g + 0.114 * o.b;
        expect(p.r, equals(o.g), reason: 'r at ${p.x},${p.y}');
        expect(p.g, closeTo(l, 1), reason: 'g at ${p.x},${p.y}');
        expect(p.b, equals(o.r), reason: 'b at ${p.x},${p.y}');
      }
    });

    test('remapColors preserves dimensions', () {
      final src = solidImage(32, 24, ColorRgb8(100, 150, 200));
      final result = remapColors(src.clone(), blue: Channel.red);
      // Channel remapping must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(24));
    });

    test('remapColors returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(80, 120, 200));
      final result = remapColors(src, red: Channel.green);
      expect(identical(result, src), isTrue);
    });

    test('remapColors swaps red and blue channels correctly', () {
      // Build a solid image with distinct r, g, b values.
      final src = solidImage(8, 8, ColorRgb8(10, 20, 30));
      // Swap red <-> blue; green stays as its default.
      remapColors(src, red: Channel.blue, blue: Channel.red);
      // After the swap, the new r should be the old b (30),
      // g unchanged (20), new b should be old r (10).
      final p = src.getPixel(0, 0);
      expect(p.r, equals(30), reason: 'red should equal original blue');
      expect(p.g, equals(20), reason: 'green should be unchanged');
      expect(p.b, equals(10), reason: 'blue should equal original red');
    });

    test('remapColors identity mapping leaves image unchanged', () {
      // Mapping each channel to itself is a no-op.
      final src = quadrantImage(16, 16);
      final orig = src.clone();
      remapColors(src);
      testImageEquals(src, orig);
    });

    test('remapColors sets red to green channel value', () {
      // Every pixel: new red = original green.
      final src = solidImage(8, 8, ColorRgb8(50, 100, 150));
      remapColors(src, red: Channel.green);
      for (final p in src) {
        expect(p.r, equals(100),
            reason: 'red should equal original green at ${p.x},${p.y}');
      }
    });
  });
}
