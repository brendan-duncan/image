import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Image', () {
    group('uint1', () {
      test('nc:1', () async {
        final i1 =
            Image(width: 32, height: 32, format: Format.uint1, numChannels: 1);
        expect(i1.width, equals(32));
        expect(i1.height, equals(32));
        expect(i1.numChannels, equals(1));
        expect(i1.format, Format.uint1);
        i1
          ..setPixelRgb(0, 0, 1, 0, 0)
          ..setPixelRgb(3, 0, 1, 0, 0)
          ..setPixelRgb(0, 1, 1, 0, 0)
          ..setPixelRgb(3, 1, 1, 0, 0);
        expect(i1.getPixel(0, 0), equals([1]));
        expect(i1.getPixel(1, 0), equals([0]));
        expect(i1.getPixel(2, 0), equals([0]));
        expect(i1.getPixel(3, 0), equals([1]));
        expect(i1.getPixel(0, 1), equals([1]));
        expect(i1.getPixel(1, 1), equals([0]));
        expect(i1.getPixel(2, 1), equals([0]));
        expect(i1.getPixel(3, 1), equals([1]));
        for (final p in i1) {
          final p2 = i1.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p.r = v;
          expect(p, equals([v]));
        }

        await testImageConversions(i1);
      });

      test('nc:2', () async {
        final i2 =
            Image(width: 32, height: 32, format: Format.uint1, numChannels: 2);
        expect(i2.width, equals(32));
        expect(i2.height, equals(32));
        expect(i2.numChannels, equals(2));
        expect(i2.format, Format.uint1);
        i2
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 1, 0, 0)
          ..setPixelRgb(0, 1, 0, 1, 0)
          ..setPixelRgb(1, 1, 1, 1, 0);
        expect(i2.getPixel(0, 0), equals([0, 0]));
        expect(i2.getPixel(1, 0), equals([1, 0]));
        expect(i2.getPixel(0, 1), equals([0, 1]));
        expect(i2.getPixel(1, 1), equals([1, 1]));
        for (final p in i2) {
          final p2 = i2.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p
            ..r = v
            ..g = v;
          expect(p, equals([v, v]));
        }

        await testImageConversions(i2);
      });

      test('nc:3', () async {
        final i3 = Image(width: 32, height: 32, format: Format.uint1);
        expect(i3.width, equals(32));
        expect(i3.height, equals(32));
        expect(i3.numChannels, equals(3));
        expect(i3.format, Format.uint1);
        i3
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 1, 0, 1)
          ..setPixelRgb(0, 1, 0, 1, 0)
          ..setPixelRgb(1, 1, 1, 1, 1);
        expect(i3.getPixel(0, 0), equals([0, 0, 0]));
        expect(i3.getPixel(1, 0), equals([1, 0, 1]));
        expect(i3.getPixel(0, 1), equals([0, 1, 0]));
        expect(i3.getPixel(1, 1), equals([1, 1, 1]));
        for (final p in i3) {
          final p2 = i3.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p
            ..r = v
            ..g = v
            ..b = v;
          expect(p, equals([v, v, v]));
        }

        await testImageConversions(i3);
      });

      test('nc:4', () async {
        final i4 =
            Image(width: 32, height: 32, format: Format.uint1, numChannels: 4);
        expect(i4.width, equals(32));
        expect(i4.height, equals(32));
        expect(i4.numChannels, equals(4));
        expect(i4.format, Format.uint1);
        i4
          ..setPixelRgba(0, 0, 0, 0, 0, 0)
          ..setPixelRgba(1, 0, 1, 0, 1, 1)
          ..setPixelRgba(0, 1, 0, 1, 0, 0)
          ..setPixelRgba(1, 1, 1, 1, 1, 1);
        expect(i4.getPixel(0, 0), equals([0, 0, 0, 0]));
        expect(i4.getPixel(1, 0), equals([1, 0, 1, 1]));
        expect(i4.getPixel(0, 1), equals([0, 1, 0, 0]));
        expect(i4.getPixel(1, 1), equals([1, 1, 1, 1]));
        for (final p in i4) {
          final p2 = i4.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p, equals([v, v, v, v]));
        }

        await testImageConversions(i4);
      });

      test('nc:3 palette', () async {
        final i5 = Image(
            width: 32, height: 32, format: Format.uint1, withPalette: true);
        expect(i5.width, equals(32));
        expect(i5.height, equals(32));
        expect(i5.numChannels, equals(3));
        expect(i5.palette!.numChannels, equals(3));
        i5.palette!.setRgb(0, 123, 42, 86);
        i5.palette!.setRgb(1, 84, 231, 52);
        i5
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 1, 0, 0)
          ..setPixelRgb(0, 1, 0, 0, 0)
          ..setPixelRgb(1, 1, 1, 0, 0);
        expect(i5.getPixel(0, 0), equals([123, 42, 86]));
        expect(i5.getPixel(1, 0), equals([84, 231, 52]));
        expect(i5.getPixel(0, 1), equals([123, 42, 86]));
        expect(i5.getPixel(1, 1), equals([84, 231, 52]));
        expect((i5.getPixel(0, 0).rNormalized * 255).floor(), equals(123));

        for (final p in i5) {
          final p2 = i5.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p.r, equals(v == 0 ? 123 : 84));
          expect(p.g, equals(v == 0 ? 42 : 231));
          expect(p.b, equals(v == 0 ? 86 : 52));
        }

        await testImageConversions(i5);
      });

      test('nc:4 palette', () async {
        final i6 = Image(
            width: 32,
            height: 32,
            format: Format.uint1,
            numChannels: 4,
            withPalette: true);
        expect(i6.width, equals(32));
        expect(i6.height, equals(32));
        expect(i6.numChannels, equals(4));
        expect(i6.palette!.numChannels, equals(4));
        i6.palette!.setRgba(0, 123, 42, 86, 128);
        i6.palette!.setRgba(1, 84, 231, 52, 200);
        i6
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 1, 0, 0)
          ..setPixelRgb(0, 1, 1, 0, 0)
          ..setPixelRgb(1, 1, 0, 0, 0);
        expect(i6.getPixel(0, 0), equals([123, 42, 86, 128]));
        expect(i6.getPixel(1, 0), equals([84, 231, 52, 200]));
        expect(i6.getPixel(0, 1), equals([84, 231, 52, 200]));
        expect(i6.getPixel(1, 1), equals([123, 42, 86, 128]));

        for (final p in i6) {
          final p2 = i6.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0x1;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p.r, equals(v == 0 ? 123 : 84));
          expect(p.g, equals(v == 0 ? 42 : 231));
          expect(p.b, equals(v == 0 ? 86 : 52));
          expect(p.a, equals(v == 0 ? 128 : 200));
        }

        await testImageConversions(i6);
      });
    });
  });
}
