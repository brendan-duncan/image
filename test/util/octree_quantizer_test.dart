import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Util', () {
    test('octreeQuantizer', () {
      final img = Image(width: 256, height: 256);
      for (final p in img) {
        p
          ..r = p.x
          ..g = p.y;
      }

      final quantizer = OctreeQuantizer(img);

      final img2 = quantizer.getIndexImage(img);

      File('$testOutputPath/util/octreeQuantizer_256.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
    });

    test('octreeQuantizer: palette has at most numberOfColors entries', () {
      // Building with numberOfColors=16 must yield a palette no larger than 16.
      final img = solidImage(32, 32, ColorRgb8(10, 20, 30));
      final q = OctreeQuantizer(img, numberOfColors: 16);
      expect(q.palette.numColors, lessThanOrEqualTo(16));
    });

    test('octreeQuantizer: getColorIndex returns valid palette index', () {
      // Any lookup must return an index within [0, palette.numColors).
      final img = solidImage(16, 16, ColorRgb8(200, 100, 50));
      final q = OctreeQuantizer(img);
      final idx = q.getColorIndex(ColorRgb8(200, 100, 50));
      expect(idx, greaterThanOrEqualTo(0));
      expect(idx, lessThan(q.palette.numColors));
    });

    test('octreeQuantizer: getQuantizedColor returns a valid color', () {
      // getQuantizedColor must return a Color with channels in 0-255.
      final img = solidImage(16, 16, ColorRgb8(80, 160, 240));
      final q = OctreeQuantizer(img);
      final c = q.getQuantizedColor(ColorRgb8(80, 160, 240));
      expect(c.r, inInclusiveRange(0, 255));
      expect(c.g, inInclusiveRange(0, 255));
      expect(c.b, inInclusiveRange(0, 255));
    });

    test('octreeQuantizer: index image has same dimensions as source', () {
      // getIndexImage must preserve width and height.
      final img = Image(width: 32, height: 32);
      for (final p in img) {
        p
          ..r = p.x * 8
          ..g = p.y * 8;
      }
      final q = OctreeQuantizer(img);
      final idx = q.getIndexImage(img);
      expect(idx.width, equals(32));
      expect(idx.height, equals(32));
    });

    test('octreeQuantizer: getColorIndex consistent with getQuantizedColor',
        () {
      // palette.get(idx, ch) must match getQuantizedColor channels.
      final img = solidImage(16, 16, ColorRgb8(128, 64, 32));
      final q = OctreeQuantizer(img);
      final testColor = ColorRgb8(128, 64, 32);
      final idx = q.getColorIndex(testColor);
      final qc = q.getQuantizedColor(testColor);
      expect(q.palette.get(idx, 0), equals(qc.r.toInt()));
      expect(q.palette.get(idx, 1), equals(qc.g.toInt()));
      expect(q.palette.get(idx, 2), equals(qc.b.toInt()));
    });
  });
}
