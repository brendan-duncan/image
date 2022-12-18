import 'package:image/image.dart';
import 'package:test/test.dart';

void ImageUint2Test() {
  group('uint2', () {
    test('nc:1', () {
      final i1 = Image(32, 32, format: Format.uint2, numChannels: 1);
      expect(i1.width, equals(32));
      expect(i1.height, equals(32));
      expect(i1.numChannels, equals(1));
      expect(i1.format, Format.uint2);
      i1.setPixelColor(0, 0, 1);
      i1.setPixelColor(1, 0, 3);
      i1.setPixelColor(0, 1, 1);
      i1.setPixelColor(1, 1, 2);
      expect(i1.getPixel(0, 0), equals([1]));
      expect(i1.getPixel(1, 0), equals([3]));
      expect(i1.getPixel(0, 1), equals([1]));
      expect(i1.getPixel(1, 1), equals([2]));
      for (var p in i1) {
        var p2 = i1.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x3;
        p.r = v;
        expect(p, equals([v]));
      }
    });

    test('nc:2', () {
      final i2 = Image(32, 32, format: Format.uint2, numChannels: 2);
      expect(i2.width, equals(32));
      expect(i2.height, equals(32));
      expect(i2.numChannels, equals(2));
      expect(i2.format, Format.uint2);
      i2.setPixelColor(0, 0, 0, 3);
      i2.setPixelColor(1, 0, 3);
      i2.setPixelColor(0, 1, 2, 1);
      i2.setPixelColor(1, 1, 1, 2);
      expect(i2.getPixel(0, 0), equals([0, 3]));
      expect(i2.getPixel(1, 0), equals([3, 0]));
      expect(i2.getPixel(0, 1), equals([2, 1]));
      expect(i2.getPixel(1, 1), equals([1, 2]));
      for (var p in i2) {
        var p2 = i2.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x3;
        p.r = v;
        p.g = v;
        expect(p, equals([v, v]));
      }
    });

    test('nc:3', () {
      final i3 = Image(32, 32, format: Format.uint2);
      expect(i3.width, equals(32));
      expect(i3.height, equals(32));
      expect(i3.numChannels, equals(3));
      expect(i3.format, Format.uint2);

      i3.setPixelColor(0, 0, 3, 0, 3);
      i3.setPixelColor(1, 0, 3, 0, 3);
      i3.setPixelColor(0, 1, 2, 1);
      i3.setPixelColor(1, 1, 3, 1, 3);
      expect(i3.getPixel(0, 0), equals([3, 0, 3]));
      expect(i3.getPixel(1, 0), equals([3, 0, 3]));
      expect(i3.getPixel(0, 1), equals([2, 1, 0]));
      expect(i3.getPixel(1, 1), equals([3, 1, 3]));
      for (var p in i3) {
        var p2 = i3.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x3;
        p.r = v;
        p.g = v;
        p.b = v;
        expect(p, equals([v, v, v]));
      }
    });

    test('nc:4', () {
      final i4 = Image(32, 32, format: Format.uint2, numChannels: 4);
      expect(i4.width, equals(32));
      expect(i4.height, equals(32));
      expect(i4.numChannels, equals(4));
      expect(i4.format, Format.uint2);
      i4.setPixelColor(0, 0, 0, 1, 2, 3);
      i4.setPixelColor(1, 0, 3, 2, 1);
      i4.setPixelColor(0, 1, 1, 0, 3, 2);
      i4.setPixelColor(1, 1, 2, 3, 0, 1);
      expect(i4.getPixel(0, 0), equals([0, 1, 2, 3]));
      expect(i4.getPixel(1, 0), equals([3, 2, 1, 0]));
      expect(i4.getPixel(0, 1), equals([1, 0, 3, 2]));
      expect(i4.getPixel(1, 1), equals([2, 3, 0, 1]));
      for (var p in i4) {
        var p2 = i4.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x3;
        p.r = v;
        p.g = v;
        p.b = v;
        p.a = v;
        expect(p, equals([v, v, v, v]));
      }
    });

    test('nc:3p', () {
      const w = 4;
      final i5 = Image(w, w, format: Format.uint2, withPalette: true);
      expect(i5.width, equals(w));
      expect(i5.height, equals(w));
      expect(i5.numChannels, equals(3));
      expect(i5.palette!.numChannels, equals(3));
      i5.palette!.setColor(0, 123, 42, 86);
      i5.palette!.setColor(1, 84, 231, 52);
      i5.palette!.setColor(2, 41, 151, 252);
      i5.palette!.setColor(3, 184, 31, 152);
      i5.setPixelColor(0, 0, 0);
      i5.setPixelColor(1, 0, 1);
      i5.setPixelColor(0, 1, 2);
      i5.setPixelColor(1, 1, 3);
      expect(i5.getPixel(0, 0), equals([123, 42, 86]));
      expect(i5.getPixel(1, 0), equals([84, 231, 52]));
      expect(i5.getPixel(0, 1), equals([41, 151, 252]));
      expect(i5.getPixel(1, 1), equals([184, 31, 152]));

      var total = 0;
      for (var y = 0; y < i5.height; ++y) {
        for (var x = 0; x < i5.width; ++x) {
          final p = i5.getPixel(x, y);
          p.index = p.x;
          total += p.index as int;
        }
      }

      final p = i5.getPixel(3, 0);
      p.index = 3;
      expect(p.index, equals(3));

      var total2 = 0;
      for (var p in i5) {
        p.index = p.x;
        total2 += p.index as int;
      }

      expect(total, equals(total2));
    });

    test('nc:4p', () {
      final i6 = Image(2, 2, format: Format.uint2, numChannels: 4,
          withPalette: true);
      expect(i6.width, equals(2));
      expect(i6.height, equals(2));
      expect(i6.numChannels, equals(4));
      expect(i6.palette!.numChannels, equals(4));
      i6.palette!.setColor(0, 123, 42, 86, 54);
      i6.palette!.setColor(1, 84, 231, 52, 192);
      i6.palette!.setColor(2, 41, 151, 252, 8);
      i6.palette!.setColor(3, 184, 31, 152, 131);
      i6.setPixelColor(0, 0, 0);
      i6.setPixelColor(1, 0, 1);
      i6.setPixelColor(0, 1, 3);
      i6.setPixelColor(1, 1, 2);
      expect(i6.getPixel(0, 0), equals([123, 42, 86, 54]));
      expect(i6.getPixel(1, 0), equals([84, 231, 52, 192]));
      expect(i6.getPixel(0, 1), equals([184, 31, 152, 131]));
      expect(i6.getPixel(1, 1), equals([41, 151, 252, 8]));
    });
  });
}
