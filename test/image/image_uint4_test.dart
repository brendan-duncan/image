import 'package:image/image.dart';
import 'package:test/test.dart';

void ImageUint4Test() {
  group('uint4', () {
    test('nc:1', () {
      final i1 = Image(32, 32, format: Format.uint4, numChannels: 1);
      expect(i1.width, equals(32));
      expect(i1.height, equals(32));
      expect(i1.numChannels, equals(1));
      expect(i1.format, Format.uint4);
      i1.setPixelColor(0, 0, 15);
      i1.setPixelColor(1, 0, 12);
      i1.setPixelColor(0, 1, 5);
      i1.setPixelColor(1, 1, 15);
      expect(i1.getPixel(0, 0), equals([15]));
      expect(i1.getPixel(1, 0), equals([12]));
      expect(i1.getPixel(0, 1), equals([5]));
      expect(i1.getPixel(1, 1), equals([15]));

      for (var p in i1) {
        var p2 = i1.getPixel(p.x, p.y);
        expect(p2, equals(p), reason: '${p2.x} ${p2.y}');
        final v = p.x & 0xf;
        p.r = v;
        expect(p, equals([v]));
      }
    });

    test('nc:2', () {
      final i2 = Image(32, 32, format: Format.uint4, numChannels: 2);
      expect(i2.width, equals(32));
      expect(i2.height, equals(32));
      expect(i2.numChannels, equals(2));
      expect(i2.format, Format.uint4);
      i2.setPixelColor(0, 0, 9, 3);
      i2.setPixelColor(1, 0, 3, 5);
      i2.setPixelColor(0, 1, 7, 14);
      i2.setPixelColor(1, 1, 15, 2);
      expect(i2.getPixel(0, 0), equals([9, 3]));
      expect(i2.getPixel(1, 0), equals([3, 5]));
      expect(i2.getPixel(0, 1), equals([7, 14]));
      expect(i2.getPixel(1, 1), equals([15, 2]));

      for (var p in i2) {
        var p2 = i2.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0xf;
        p.r = v;
        p.g = v;
        expect(p, equals([v, v]));
      }
    });

    test('nc:3', () {
      final i3 = Image(32, 32, format: Format.uint4);
      expect(i3.width, equals(32));
      expect(i3.height, equals(32));
      expect(i3.numChannels, equals(3));
      expect(i3.format, Format.uint4);
      i3.setPixelColor(0, 0, 0, 14, 3);
      i3.setPixelColor(1, 0, 1, 0, 2);
      i3.setPixelColor(i3.width - 1, 0, 1, 13, 6);
      i3.setPixelColor(0, 1, 2, 11, 9);
      i3.setPixelColor(i3.width - 1, i3.height - 1, 3, 1, 13);
      expect(i3.getPixel(0, 0), equals([0, 14, 3]));
      expect(i3.getPixel(1, 0), equals([1, 0, 2]));
      expect(i3.getPixel(i3.width - 1, 0), equals([1, 13, 6]));
      expect(i3.getPixel(0, 1), equals([2, 11, 9]));
      expect(i3.getPixel(i3.width - 1, i3.height - 1), equals([3, 1, 13]));

      for (var p in i3) {
        var p2 = i3.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0xf;
        p.r = v;
        p.g = v;
        p.b = v;
        expect(p, equals([v, v, v]));
      }
    });

    test('nc:4', () {
      final i4 = Image(32, 32, format: Format.uint4, numChannels: 4);
      expect(i4.width, equals(32));
      expect(i4.height, equals(32));
      expect(i4.numChannels, equals(4));
      expect(i4.format, Format.uint4);
      i4.setPixelColor(0, 0, 10, 1, 2, 3);
      i4.setPixelColor(1, 0, 3, 12, 1);
      i4.setPixelColor(0, 1, 1, 0, 15, 2);
      i4.setPixelColor(1, 1, 2, 13, 0, 1);
      expect(i4.getPixel(0, 0), equals([10, 1, 2, 3]));
      expect(i4.getPixel(1, 0), equals([3, 12, 1, 0]));
      expect(i4.getPixel(0, 1), equals([1, 0, 15, 2]));
      expect(i4.getPixel(1, 1), equals([2, 13, 0, 1]));
      for (var p in i4) {
        var p2 = i4.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0xf;
        p.r = v;
        p.g = v;
        p.b = v;
        p.a = v;
        expect(p, equals([v, v, v, v]));
      }
    });

    test('nc:3p', () {
      final i5 = Image(32, 32, format: Format.uint4, withPalette: true);
      expect(i5.width, equals(32));
      expect(i5.height, equals(32));
      expect(i5.numChannels, equals(3));
      expect(i5.palette!.numChannels, equals(3));
      i5.palette!.setColor(0, 123, 42, 86);
      i5.palette!.setColor(7, 84, 231, 52);
      i5.palette!.setColor(12, 41, 151, 252);
      i5.palette!.setColor(14, 184, 31, 152);
      i5.setPixelColor(0, 0, 0);
      i5.setPixelColor(1, 0, 12);
      i5.setPixelColor(0, 1, 14);
      i5.setPixelColor(1, 1, 7);
      expect(i5.getPixel(0, 0), equals([123, 42, 86]));
      expect(i5.getPixel(1, 0), equals([41, 151, 252]));
      expect(i5.getPixel(0, 1), equals([184, 31, 152]));
      expect(i5.getPixel(1, 1), equals([84, 231, 52]));

      for (var i = 0; i < 16; ++i) {
        i5.palette!.setColor(i, i, i, i);
      }

      for (var p in i5) {
        final p2 = i5.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0xf;
        i5.setPixelColor(p.x, p.y, v);
        expect(p, equals([v, v, v]));
      }
    });

    test('nc:4p', () {
      final i6 = Image(2, 2, format: Format.uint4, numChannels: 4,
          withPalette: true);
      expect(i6.width, equals(2));
      expect(i6.height, equals(2));
      expect(i6.numChannels, equals(4));
      expect(i6.palette!.numChannels, equals(4));
      i6.palette!.setColor(0, 123, 42, 86, 54);
      i6.palette!.setColor(11, 84, 231, 52, 192);
      i6.palette!.setColor(7, 41, 151, 252, 8);
      i6.palette!.setColor(13, 184, 31, 152, 131);
      i6.setPixelColor(0, 0, 0);
      i6.setPixelColor(1, 0, 11);
      i6.setPixelColor(0, 1, 13);
      i6.setPixelColor(1, 1, 7);
      expect(i6.getPixel(0, 0), equals([123, 42, 86, 54]));
      expect(i6.getPixel(1, 0), equals([84, 231, 52, 192]));
      expect(i6.getPixel(0, 1), equals([184, 31, 152, 131]));
      expect(i6.getPixel(1, 1), equals([41, 151, 252, 8]));
    });
  });
}
