import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Color bug fixes', () {
    test('BinaryQuantizer getColorIndexRgb matches getColorIndex', () {
      final q = BinaryQuantizer();
      for (final v in [0, 50, 127, 128, 200, 255]) {
        expect(q.getColorIndexRgb(v, v, v),
            equals(q.getColorIndex(ColorRgb8(v, v, v))),
            reason: 'value $v');
      }
      expect(q.getColorIndexRgb(200, 200, 200), equals(1));
    });

    test('ditherImage with BinaryQuantizer keeps dark pixels black', () {
      final src = solidImage(8, 8, ColorRgb8(30, 30, 30));
      final dithered = ditherImage(src, quantizer: BinaryQuantizer());
      var black = 0;
      for (final p in dithered) {
        if (p.r == 0) {
          black++;
        }
      }
      expect(black, greaterThan(32));
    });

    test('convert float to 1 channel keeps fractional luminance', () {
      final src = Image(width: 2, height: 2, format: Format.float32);
      for (final p in src) {
        p.setRgb(0.5, 0.5, 0.5);
      }
      final gray = src.convert(numChannels: 1);
      for (final p in gray) {
        expect(p.r, closeTo(0.5, 1e-6));
      }
    });

    test('convert uint8 to 1 channel floors luminance', () {
      final src = solidImage(2, 2, ColorRgb8(100, 150, 200));
      final gray = src.convert(numChannels: 1);
      for (final p in gray) {
        // 0.299 * 100 + 0.587 * 150 + 0.114 * 200 = 140.75
        expect(p.r, equals(140));
      }
    });

    test('convert RGBA withPalette keeps alpha', () {
      final src = Image(width: 2, height: 1, numChannels: 4);
      src.getPixel(0, 0).setRgba(10, 20, 30, 255);
      src.getPixel(1, 0).setRgba(10, 20, 30, 128);
      final indexed = src.convert(withPalette: true);
      expect(indexed.hasPalette, isTrue);
      expect(indexed.getPixel(0, 0).a, equals(255));
      expect(indexed.getPixel(1, 0).a, equals(128));
      expect(indexed.getPixel(1, 0).r, equals(10));
      expect(indexed.getPixel(1, 0).b, equals(30));
    });
  });
}
