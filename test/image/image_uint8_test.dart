import 'package:image/image.dart';
import 'package:test/test.dart';

void ImageUint8Test() {
  group('uint8', ()
  {
    test('nc:1', () {
      final i1 = Image(2, 2, numChannels: 1);
      expect(i1.width, equals(2));
      expect(i1.height, equals(2));
      expect(i1.numChannels, equals(1));
      expect(i1.format, Format.uint8);
      i1.setPixelColor(0, 0, 32);
      i1.setPixelColor(1, 0, 64);
      i1.setPixelColor(0, 1, 128);
      i1.setPixelColor(1, 1, 255);
      expect(i1.getPixel(0, 0), equals([32]));
      expect(i1.getPixel(1, 0), equals([64]));
      expect(i1.getPixel(0, 1), equals([128]));
      expect(i1.getPixel(1, 1), equals([255]));

      i1.clear(ColorRgba8(5));
      var total = 0;
      for (var p in i1) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals(20));
    });

    test('nc:2', () {
      final i2 = Image(2, 2, numChannels: 2);
      expect(i2.width, equals(2));
      expect(i2.height, equals(2));
      expect(i2.numChannels, equals(2));
      i2.setPixelColor(0, 0, 32, 64);
      i2.setPixelColor(1, 0, 64, 32);
      i2.setPixelColor(0, 1, 128, 52);
      i2.setPixelColor(1, 1, 255, 84);
      expect(i2.getPixel(0, 0), equals([32, 64]));
      expect(i2.getPixel(1, 0), equals([64, 32]));
      expect(i2.getPixel(0, 1), equals([128, 52]));
      expect(i2.getPixel(1, 1), equals([255, 84]));

      i2.clear(ColorRgba8(5, 10));
      var total = 0;
      for (var p in i2) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals(60));
    });

    test('nc:3', () {
      final i3 = Image(2, 2);
      expect(i3.width, equals(2));
      expect(i3.height, equals(2));
      expect(i3.numChannels, equals(3));
      i3.setPixelColor(0, 0, 32, 64, 86);
      i3.setPixelColor(1, 0, 64, 32, 14);
      i3.setPixelColor(0, 1, 128, 52, 5);
      i3.setPixelColor(1, 1, 255, 84, 94);
      expect(i3.getPixel(0, 0), equals([32, 64, 86]));
      expect(i3.getPixel(1, 0), equals([64, 32, 14]));
      expect(i3.getPixel(0, 1), equals([128, 52, 5]));
      expect(i3.getPixel(1, 1), equals([255, 84, 94]));

      final i3b = Image(2, 2);
      expect(i3b.width, equals(2));
      expect(i3b.height, equals(2));
      expect(i3b.numChannels, equals(3));

      i3.clear(ColorRgba8(5, 10, 5));
      var total = 0;
      for (var p in i3) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals(80));
    });

    test('nc:4', () {
      final i4 = Image(2, 2, numChannels: 4);
      expect(i4.width, equals(2));
      expect(i4.height, equals(2));
      expect(i4.numChannels, equals(4));
      i4.setPixelColor(0, 0, 32, 64, 86, 144);
      i4.setPixelColor(1, 0, 64, 32, 14, 214);
      i4.setPixelColor(0, 1, 128, 52, 5, 52);
      i4.setPixelColor(1, 1, 255, 84, 94, 82);
      expect(i4.getPixel(0, 0), equals([32, 64, 86, 144]));
      expect(i4.getPixel(1, 0), equals([64, 32, 14, 214]));
      expect(i4.getPixel(0, 1), equals([128, 52, 5, 52]));
      expect(i4.getPixel(1, 1), equals([255, 84, 94, 82]));

      i4.clear(ColorRgba8(5, 10, 5, 10));
      var total = 0;
      for (var p in i4) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals(120));
    });

    test('nc:3p', () {
      final i5 = Image(2, 2, withPalette: true);
      expect(i5.width, equals(2));
      expect(i5.height, equals(2));
      expect(i5.numChannels, equals(3));
      expect(i5.palette!.numChannels, equals(3));
      i5.palette!.setColor(50, 123, 42, 86);
      i5.palette!.setColor(125, 84, 231, 52);
      i5.setPixelColor(0, 0, 50);
      i5.setPixelColor(1, 0, 125);
      i5.setPixelColor(0, 1, 42);
      i5.setPixelColor(1, 1, 0);
      expect(i5.getPixel(0, 0), equals([123, 42, 86]));
      expect(i5.getPixel(1, 0), equals([84, 231, 52]));
      expect(i5.getPixel(0, 1), equals([0, 0, 0]));
      expect(i5.getPixel(1, 1), equals([0, 0, 0]));

      i5.clear(ColorRgba8(50, 10, 5, 10));
      var total = 0;
      for (var p in i5) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals((123 + 42 + 86) * 4));

      for (var p in i5) {
        final i = p.index;
        i5.setPixel(p.x, p.y, p);
        expect(p.index, equals(i));
      }
    });

    test('nc:4p', () {
      final i6 = Image(2, 2, numChannels: 4, withPalette: true);
      expect(i6.width, equals(2));
      expect(i6.height, equals(2));
      expect(i6.numChannels, equals(4));
      expect(i6.palette!.numChannels, equals(4));
      i6.palette!.setColor(50, 123, 42, 86, 128);
      i6.palette!.setColor(125, 84, 231, 52, 200);
      i6.setPixelColor(0, 0, 50);
      i6.setPixelColor(1, 0, 125);
      i6.setPixelColor(0, 1, 42);
      i6.setPixelColor(1, 1, 0);
      expect(i6.getPixel(0, 0), equals([123, 42, 86, 128]));
      expect(i6.getPixel(1, 0), equals([84, 231, 52, 200]));
      expect(i6.getPixel(0, 1), equals([0, 0, 0, 0]));
      expect(i6.getPixel(1, 1), equals([0, 0, 0, 0]));

      i6.clear(ColorRgba8(50, 10, 5, 10));
      var total = 0;
      for (var p in i6) {
        for (var c in p) {
          total += c as int;
        }
      }
      expect(total, equals((123 + 42 + 86 + 128) * 4));
    });

    test('uint8.convert', () {
      final i1 = Image(2, 2, numChannels: 1);
      i1.setPixelColor(0, 0, 32);
      i1.setPixelColor(1, 0, 64);
      i1.setPixelColor(0, 1, 128);
      i1.setPixelColor(1, 1, 255);

      final i1_1 = i1.convert(numChannels: 1);
      expect(i1_1.format, equals(Format.uint8));
      expect(i1_1.numChannels, equals(1));
      expect(i1_1.getPixel(0, 0), equals([32]));
      expect(i1_1.getPixel(1, 0), equals([64]));
      expect(i1_1.getPixel(0, 1), equals([128]));
      expect(i1_1.getPixel(1, 1), equals([255]));

      final i1_2 = i1.convert(numChannels: 2);
      expect(i1_2.format, equals(Format.uint8));
      expect(i1_2.numChannels, equals(2));
      expect(i1_2.getPixel(0, 0), equals([32, 32]));
      expect(i1_2.getPixel(1, 0), equals([64, 64]));
      expect(i1_2.getPixel(0, 1), equals([128, 128]));
      expect(i1_2.getPixel(1, 1), equals([255, 255]));

      final i1_3 = i1.convert(numChannels: 3);
      expect(i1_3.format, equals(Format.uint8));
      expect(i1_3.numChannels, equals(3));
      expect(i1_3.getPixel(0, 0), equals([32, 32, 32]));
      expect(i1_3.getPixel(1, 0), equals([64, 64, 64]));
      expect(i1_3.getPixel(0, 1), equals([128, 128, 128]));
      expect(i1_3.getPixel(1, 1), equals([255, 255, 255]));

      final i1_4 = i1.convert(numChannels: 4, alpha: 128);
      expect(i1_4.format, equals(Format.uint8));
      expect(i1_4.numChannels, equals(4));
      expect(i1_4.getPixel(0, 0), equals([32, 32, 32, 128]));
      expect(i1_4.getPixel(1, 0), equals([64, 64, 64, 128]));
      expect(i1_4.getPixel(0, 1), equals([128, 128, 128, 128]));
      expect(i1_4.getPixel(1, 1), equals([255, 255, 255, 128]));

      final i4_3 = i1_4.convert(numChannels: 3);
      expect(i4_3.format, equals(Format.uint8));
      expect(i4_3.numChannels, equals(3));
      expect(i4_3.getPixel(0, 0), equals([32, 32, 32]));
      expect(i4_3.getPixel(1, 0), equals([64, 64, 64]));
      expect(i4_3.getPixel(0, 1), equals([128, 128, 128]));
      expect(i4_3.getPixel(1, 1), equals([255, 255, 255]));
    });
  });
}
