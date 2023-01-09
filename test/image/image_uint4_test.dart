import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Image', () {
    group('uint4', () {
      test('nc:1', () async {
        final i1 =
            Image(width: 32, height: 32, format: Format.uint4, numChannels: 1);
        expect(i1.width, equals(32));
        expect(i1.height, equals(32));
        expect(i1.numChannels, equals(1));
        expect(i1.format, Format.uint4);
        i1
          ..setPixelRgb(0, 0, 15, 0, 0)
          ..setPixelRgb(1, 0, 12, 0, 0)
          ..setPixelRgb(0, 1, 5, 0, 0)
          ..setPixelRgb(1, 1, 15, 0, 0);
        expect(i1.getPixel(0, 0), equals([15]));
        expect(i1.getPixel(1, 0), equals([12]));
        expect(i1.getPixel(0, 1), equals([5]));
        expect(i1.getPixel(1, 1), equals([15]));

        for (final p in i1) {
          final p2 = i1.getPixel(p.x, p.y);
          expect(p2, equals(p), reason: '${p2.x} ${p2.y}');
          final v = p.x & 0xf;
          p.r = v;
          expect(p, equals([v]));
        }

        await testImageConversions(i1);
      });

      test('nc:2', () async {
        final i2 =
            Image(width: 32, height: 32, format: Format.uint4, numChannels: 2);
        expect(i2.width, equals(32));
        expect(i2.height, equals(32));
        expect(i2.numChannels, equals(2));
        expect(i2.format, Format.uint4);
        i2
          ..setPixelRgb(0, 0, 9, 3, 0)
          ..setPixelRgb(1, 0, 3, 5, 0)
          ..setPixelRgb(0, 1, 7, 14, 0)
          ..setPixelRgb(1, 1, 15, 2, 0);
        expect(i2.getPixel(0, 0), equals([9, 3]));
        expect(i2.getPixel(1, 0), equals([3, 5]));
        expect(i2.getPixel(0, 1), equals([7, 14]));
        expect(i2.getPixel(1, 1), equals([15, 2]));

        for (final p in i2) {
          final p2 = i2.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0xf;
          p
            ..r = v
            ..g = v;
          expect(p, equals([v, v]));
        }

        await testImageConversions(i2);
      });

      test('nc:3', () async {
        final i3 = Image(width: 32, height: 32, format: Format.uint4);
        expect(i3.width, equals(32));
        expect(i3.height, equals(32));
        expect(i3.numChannels, equals(3));
        expect(i3.format, Format.uint4);
        i3
          ..setPixelRgb(0, 0, 0, 14, 3)
          ..setPixelRgb(1, 0, 1, 0, 2)
          ..setPixelRgb(i3.width - 1, 0, 1, 13, 6)
          ..setPixelRgb(0, 1, 2, 11, 9)
          ..setPixelRgb(i3.width - 1, i3.height - 1, 3, 1, 13);
        expect(i3.getPixel(0, 0), equals([0, 14, 3]));
        expect(i3.getPixel(1, 0), equals([1, 0, 2]));
        expect(i3.getPixel(i3.width - 1, 0), equals([1, 13, 6]));
        expect(i3.getPixel(0, 1), equals([2, 11, 9]));
        expect(i3.getPixel(i3.width - 1, i3.height - 1), equals([3, 1, 13]));

        for (final p in i3) {
          final p2 = i3.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0xf;
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
            Image(width: 32, height: 32, format: Format.uint4, numChannels: 4);
        expect(i4.width, equals(32));
        expect(i4.height, equals(32));
        expect(i4.numChannels, equals(4));
        expect(i4.format, Format.uint4);
        i4
          ..setPixelRgba(0, 0, 10, 1, 2, 3)
          ..setPixelRgba(1, 0, 3, 12, 1, 0)
          ..setPixelRgba(0, 1, 1, 0, 15, 2)
          ..setPixelRgba(1, 1, 2, 13, 0, 1);
        expect(i4.getPixel(0, 0), equals([10, 1, 2, 3]));
        expect(i4.getPixel(1, 0), equals([3, 12, 1, 0]));
        expect(i4.getPixel(0, 1), equals([1, 0, 15, 2]));
        expect(i4.getPixel(1, 1), equals([2, 13, 0, 1]));
        for (final p in i4) {
          final p2 = i4.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0xf;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p, equals([v, v, v, v]));
        }

        await testImageConversions(i4);
      });

      test('nc:3p', () async {
        final i5 = Image(
            width: 32, height: 32, format: Format.uint4, withPalette: true);
        expect(i5.width, equals(32));
        expect(i5.height, equals(32));
        expect(i5.numChannels, equals(3));
        expect(i5.palette!.numChannels, equals(3));
        i5.palette!.setRgb(0, 123, 42, 86);
        i5.palette!.setRgb(7, 84, 231, 52);
        i5.palette!.setRgb(12, 41, 151, 252);
        i5.palette!.setRgb(14, 184, 31, 152);
        i5
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 12, 0, 0)
          ..setPixelRgb(0, 1, 14, 0, 0)
          ..setPixelRgb(1, 1, 7, 0, 0);
        expect(i5.getPixel(0, 0), equals([123, 42, 86]));
        expect(i5.getPixel(1, 0), equals([41, 151, 252]));
        expect(i5.getPixel(0, 1), equals([184, 31, 152]));
        expect(i5.getPixel(1, 1), equals([84, 231, 52]));

        for (var i = 0; i < 16; ++i) {
          i5.palette!.setRgb(i, i, i, i);
        }

        for (final p in i5) {
          final p2 = i5.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = p.x & 0xf;
          i5.setPixelRgb(p.x, p.y, v, 0, 0);
          expect(p, equals([v, v, v]));
        }

        await testImageConversions(i5);
      });

      test('nc:4p', () async {
        final i6 = Image(
            width: 32,
            height: 32,
            format: Format.uint4,
            numChannels: 4,
            withPalette: true);
        expect(i6.width, equals(32));
        expect(i6.height, equals(32));
        expect(i6.numChannels, equals(4));
        expect(i6.palette!.numChannels, equals(4));
        i6.palette!.setRgba(0, 123, 42, 86, 54);
        i6.palette!.setRgba(11, 84, 231, 52, 192);
        i6.palette!.setRgba(7, 41, 151, 252, 8);
        i6.palette!.setRgba(13, 184, 31, 152, 131);
        i6
          ..setPixelRgb(0, 0, 0, 0, 0)
          ..setPixelRgb(1, 0, 11, 0, 0)
          ..setPixelRgb(0, 1, 13, 0, 0)
          ..setPixelRgb(1, 1, 7, 0, 0);
        expect(i6.getPixel(0, 0), equals([123, 42, 86, 54]));
        expect(i6.getPixel(1, 0), equals([84, 231, 52, 192]));
        expect(i6.getPixel(0, 1), equals([184, 31, 152, 131]));
        expect(i6.getPixel(1, 1), equals([41, 151, 252, 8]));

        await testImageConversions(i6);
      });
    });
  });
}
