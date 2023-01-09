import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Image', () {
    group('uint8', () {
      test('nc:1', () async {
        final i1 = Image(width: 32, height: 32, numChannels: 1);
        expect(i1.width, equals(32));
        expect(i1.height, equals(32));
        expect(i1.numChannels, equals(1));
        expect(i1.format, Format.uint8);
        i1
          ..setPixelRgb(0, 0, 32, 0, 0)
          ..setPixelRgb(1, 0, 64, 0, 0)
          ..setPixelRgb(0, 1, 128, 0, 0)
          ..setPixelRgb(1, 1, 255, 0, 0);
        expect(i1.getPixel(0, 0), equals([32]));
        expect(i1.getPixel(1, 0), equals([64]));
        expect(i1.getPixel(0, 1), equals([128]));
        expect(i1.getPixel(1, 1), equals([255]));

        for (final p in i1) {
          final p2 = i1.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = (p.x * 8) & 0xff;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p, equals([v]));
        }

        //await testImageConversions(i1);
      });

      test('nc:2', () async {
        final i2 = Image(width: 32, height: 32, numChannels: 2);
        expect(i2.width, equals(32));
        expect(i2.height, equals(32));
        expect(i2.numChannels, equals(2));
        i2
          ..setPixelRgb(0, 0, 32, 64, 0)
          ..setPixelRgb(1, 0, 64, 32, 0)
          ..setPixelRgb(0, 1, 128, 52, 0)
          ..setPixelRgb(1, 1, 255, 84, 0);
        expect(i2.getPixel(0, 0), equals([32, 64]));
        expect(i2.getPixel(1, 0), equals([64, 32]));
        expect(i2.getPixel(0, 1), equals([128, 52]));
        expect(i2.getPixel(1, 1), equals([255, 84]));

        for (final p in i2) {
          final p2 = i2.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = (p.x * 8) & 0xff;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p, equals([v, v]));
        }

        //await testImageConversions(i2);
      });

      test('nc:3', () async {
        final i3 = Image(width: 32, height: 32);
        expect(i3.width, equals(32));
        expect(i3.height, equals(32));
        expect(i3.numChannels, equals(3));
        i3
          ..setPixelRgb(0, 0, 32, 64, 86)
          ..setPixelRgb(1, 0, 64, 32, 14)
          ..setPixelRgb(0, 1, 128, 52, 5)
          ..setPixelRgb(1, 1, 255, 84, 94);
        expect(i3.getPixel(0, 0), equals([32, 64, 86]));
        expect(i3.getPixel(1, 0), equals([64, 32, 14]));
        expect(i3.getPixel(0, 1), equals([128, 52, 5]));
        expect(i3.getPixel(1, 1), equals([255, 84, 94]));

        for (final p in i3) {
          final p2 = i3.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = (p.x * 8) & 0xff;
          p
            ..r = v
            ..g = v
            ..b = v
            ..a = v;
          expect(p, equals([v, v, v]));
        }

        await testImageConversions(i3);
      });

      test('nc:4', () async {
        final i4 = Image(width: 32, height: 32, numChannels: 4);
        expect(i4.width, equals(32));
        expect(i4.height, equals(32));
        expect(i4.numChannels, equals(4));
        i4
          ..setPixelRgba(0, 0, 32, 64, 86, 144)
          ..setPixelRgba(1, 0, 64, 32, 14, 214)
          ..setPixelRgba(0, 1, 128, 52, 5, 52)
          ..setPixelRgba(1, 1, 255, 84, 94, 82);
        expect(i4.getPixel(0, 0), equals([32, 64, 86, 144]));
        expect(i4.getPixel(1, 0), equals([64, 32, 14, 214]));
        expect(i4.getPixel(0, 1), equals([128, 52, 5, 52]));
        expect(i4.getPixel(1, 1), equals([255, 84, 94, 82]));

        for (final p in i4) {
          final p2 = i4.getPixel(p.x, p.y);
          expect(p2, equals(p));
          final v = (p.x * 8) & 0xff;
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
        final i5 = Image(width: 32, height: 32, withPalette: true);
        expect(i5.width, equals(32));
        expect(i5.height, equals(32));
        expect(i5.numChannels, equals(3));
        expect(i5.palette!.numChannels, equals(3));
        i5.palette!.setRgb(50, 123, 42, 86);
        i5.palette!.setRgb(125, 84, 231, 52);
        i5
          ..setPixelRgb(0, 0, 50, 0, 0)
          ..setPixelRgb(1, 0, 125, 0, 0)
          ..setPixelRgb(0, 1, 42, 0, 0)
          ..setPixelRgb(1, 1, 0, 0, 0);
        expect(i5.getPixel(0, 0), equals([123, 42, 86]));
        expect(i5.getPixel(1, 0), equals([84, 231, 52]));
        expect(i5.getPixel(0, 1), equals([0, 0, 0]));
        expect(i5.getPixel(1, 1), equals([0, 0, 0]));

        i5.clear(ColorRgba8(50, 10, 5, 10));

        for (final p in i5) {
          final i = p.index;
          i5.setPixel(p.x, p.y, p);
          expect(p.index, equals(i));
        }

        await testImageConversions(i5);
      });

      test('nc:4p', () async {
        final i6 =
            Image(width: 32, height: 32, numChannels: 4, withPalette: true);
        expect(i6.width, equals(32));
        expect(i6.height, equals(32));
        expect(i6.numChannels, equals(4));
        expect(i6.palette!.numChannels, equals(4));
        i6.palette!.setRgba(50, 123, 42, 86, 128);
        i6.palette!.setRgba(125, 84, 231, 52, 200);
        i6
          ..setPixelRgb(0, 0, 50, 0, 0)
          ..setPixelRgb(1, 0, 125, 0, 0)
          ..setPixelRgb(0, 1, 42, 0, 0)
          ..setPixelRgb(1, 1, 0, 0, 0);
        expect(i6.getPixel(0, 0), equals([123, 42, 86, 128]));
        expect(i6.getPixel(1, 0), equals([84, 231, 52, 200]));
        expect(i6.getPixel(0, 1), equals([0, 0, 0, 0]));
        expect(i6.getPixel(1, 1), equals([0, 0, 0, 0]));

        i6.clear(ColorRgba8(50, 10, 5, 10));

        await testImageConversions(i6);
      });

      test('convert', () {
        final i1 = Image(width: 2, height: 2, numChannels: 1)
          ..setPixelRgb(0, 0, 32, 0, 0)
          ..setPixelRgb(1, 0, 64, 0, 0)
          ..setPixelRgb(0, 1, 128, 0, 0)
          ..setPixelRgb(1, 1, 255, 0, 0);

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
  });
}
