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

    test('octreeQuantizer: folded colors map to nearby palette entries', () {
      // https://github.com/brendan-duncan/image/issues/792
      // With more distinct colors than palette entries, the octree folds
      // leaves into internal nodes. Lookups that stop at a partially-folded
      // internal node used to fall through to palette index 0, turning
      // bright pixels near-black.
      final src = Image(width: 256, height: 256);
      for (var y = 0; y < 256; y++) {
        for (var x = 0; x < 256; x++) {
          if (x < 48) {
            src.setPixelRgb(x, y, x % 40, x % 40, x % 40);
          } else {
            src.setPixelRgb(
                x, y, 100 + (x ~/ 2) % 156, 100 + (y ~/ 2) % 156, 150);
          }
        }
      }

      final q = quantize(src, method: QuantizeMethod.octree);
      final pal = q.palette!;

      var worst = 0;
      for (var y = 0; y < 256; y++) {
        for (var x = 0; x < 256; x++) {
          final s = src.getPixel(x, y);
          final i = q.getPixel(x, y).index.toInt();
          final dr = s.r.toInt() - pal.get(i, 0).toInt();
          final dg = s.g.toInt() - pal.get(i, 1).toInt();
          final db = s.b.toInt() - pal.get(i, 2).toInt();
          final d = dr * dr + dg * dg + db * db;
          if (d > worst) {
            worst = d;
          }
        }
      }
      // Before the fix the worst error was > 200 per pixel (bright colors
      // assigned to a near-black entry).
      expect(worst, lessThan(32 * 32));
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
