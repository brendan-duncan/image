import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void ImageUint1Test() {
  group('uint1', () {
    test('nc:1', () {
      final i1 = Image(32, 32, format: Format.uint1, numChannels: 1);
      expect(i1.width, equals(32));
      expect(i1.height, equals(32));
      expect(i1.numChannels, equals(1));
      expect(i1.format, Format.uint1);
      i1.setPixelColor(0, 0, 1);
      i1.setPixelColor(3, 0, 1);
      i1.setPixelColor(0, 1, 1);
      i1.setPixelColor(3, 1, 1);
      expect(i1.getPixel(0, 0), equals([1]));
      expect(i1.getPixel(1, 0), equals([0]));
      expect(i1.getPixel(2, 0), equals([0]));
      expect(i1.getPixel(3, 0), equals([1]));
      expect(i1.getPixel(0, 1), equals([1]));
      expect(i1.getPixel(1, 1), equals([0]));
      expect(i1.getPixel(2, 1), equals([0]));
      expect(i1.getPixel(3, 1), equals([1]));
      for (var p in i1) {
        var p2 = i1.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x1;
        p.r = v;
        expect(p, equals([v]));
      }
    });

    test('nc:2', () {
      final i2 = Image(32, 32, format: Format.uint1, numChannels: 2);
      expect(i2.width, equals(32));
      expect(i2.height, equals(32));
      expect(i2.numChannels, equals(2));
      expect(i2.format, Format.uint1);
      i2.setPixelColor(0, 0, 0);
      i2.setPixelColor(1, 0, 1);
      i2.setPixelColor(0, 1, 0, 1);
      i2.setPixelColor(1, 1, 1, 1);
      expect(i2.getPixel(0, 0), equals([0, 0]));
      expect(i2.getPixel(1, 0), equals([1, 0]));
      expect(i2.getPixel(0, 1), equals([0, 1]));
      expect(i2.getPixel(1, 1), equals([1, 1]));
      for (var p in i2) {
        var p2 = i2.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x1;
        p.r = v;
        p.g = v;
        expect(p, equals([v, v]));
      }
    });

    test('nc:3', () {
      final i3 = Image(32, 32, format: Format.uint1);
      expect(i3.width, equals(32));
      expect(i3.height, equals(32));
      expect(i3.numChannels, equals(3));
      expect(i3.format, Format.uint1);
      i3.setPixelColor(0, 0, 0);
      i3.setPixelColor(1, 0, 1, 0, 1);
      i3.setPixelColor(0, 1, 0, 1);
      i3.setPixelColor(1, 1, 1, 1, 1);
      expect(i3.getPixel(0, 0), equals([0, 0, 0]));
      expect(i3.getPixel(1, 0), equals([1, 0, 1]));
      expect(i3.getPixel(0, 1), equals([0, 1, 0]));
      expect(i3.getPixel(1, 1), equals([1, 1, 1]));
      for (var p in i3) {
        var p2 = i3.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x1;
        p.r = v;
        p.g = v;
        p.b = v;
        expect(p, equals([v, v, v]));
      }
    });

    test('nc:4', () {
      final i4 = Image(32, 32, format: Format.uint1, numChannels: 4);
      expect(i4.width, equals(32));
      expect(i4.height, equals(32));
      expect(i4.numChannels, equals(4));
      expect(i4.format, Format.uint1);
      i4.setPixelColor(0, 0, 0);
      i4.setPixelColor(1, 0, 1, 0, 1, 1);
      i4.setPixelColor(0, 1, 0, 1);
      i4.setPixelColor(1, 1, 1, 1, 1, 1);
      expect(i4.getPixel(0, 0), equals([0, 0, 0, 0]));
      expect(i4.getPixel(1, 0), equals([1, 0, 1, 1]));
      expect(i4.getPixel(0, 1), equals([0, 1, 0, 0]));
      expect(i4.getPixel(1, 1), equals([1, 1, 1, 1]));
      for (var p in i4) {
        var p2 = i4.getPixel(p.x, p.y);
        expect(p2, equals(p));
        final v = p.x & 0x1;
        p.r = v;
        p.g = v;
        p.b = v;
        p.a = v;
        expect(p, equals([v, v, v, v]));
      }
    });

    test('nc:3 palette', () {
      final i5 = Image(2, 2, format: Format.uint1, withPalette: true);
      expect(i5.width, equals(2));
      expect(i5.height, equals(2));
      expect(i5.numChannels, equals(3));
      expect(i5.palette!.numChannels, equals(3));
      i5.palette!.setColor(0, 123, 42, 86);
      i5.palette!.setColor(1, 84, 231, 52);
      i5.setPixelColor(0, 0, 0);
      i5.setPixelColor(1, 0, 1);
      i5.setPixelColor(0, 1, 0);
      i5.setPixelColor(1, 1, 1);
      expect(i5.getPixel(0, 0), equals([123, 42, 86]));
      expect(i5.getPixel(1, 0), equals([84, 231, 52]));
      expect(i5.getPixel(0, 1), equals([123, 42, 86]));
      expect(i5.getPixel(1, 1), equals([84, 231, 52]));
    });

    test('nc:4 palette', () {
      final i6 = Image(2, 2, format: Format.uint1, numChannels: 4,
          withPalette: true);
      expect(i6.width, equals(2));
      expect(i6.height, equals(2));
      expect(i6.numChannels, equals(4));
      expect(i6.palette!.numChannels, equals(4));
      i6.palette!.setColor(0, 123, 42, 86, 128);
      i6.palette!.setColor(1, 84, 231, 52, 200);
      i6.setPixelColor(0, 0, 0);
      i6.setPixelColor(1, 0, 1);
      i6.setPixelColor(0, 1, 1);
      i6.setPixelColor(1, 1, 0);
      expect(i6.getPixel(0, 0), equals([123, 42, 86, 128]));
      expect(i6.getPixel(1, 0), equals([84, 231, 52, 200]));
      expect(i6.getPixel(0, 1), equals([84, 231, 52, 200]));
      expect(i6.getPixel(1, 1), equals([123, 42, 86, 128]));
    });
  });
}
