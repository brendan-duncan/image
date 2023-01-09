import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Image', () {
    group('uint16', () {
      test('nc:1', () async {
        final i1 =
            Image(width: 32, height: 32, format: Format.uint16, numChannels: 1);
        expect(i1.width, equals(32));
        expect(i1.height, equals(32));
        expect(i1.numChannels, equals(1));
        expect(i1.format, Format.uint16);
        i1
          ..setPixelRgb(0, 0, 32, 0, 0)
          ..setPixelRgb(1, 0, 64, 0, 0)
          ..setPixelRgb(0, 1, 7425, 0, 0)
          ..setPixelRgb(1, 1, 52145, 0, 0);
        expect(i1.getPixel(0, 0), equals([32]));
        expect(i1.getPixel(1, 0), equals([64]));
        expect(i1.getPixel(0, 1), equals([7425]));
        expect(i1.getPixel(1, 1), equals([52145]));

        await testImageConversions(i1);
      });

      test('nc:2', () async {
        final i2 =
            Image(width: 32, height: 32, format: Format.uint16, numChannels: 2);
        expect(i2.width, equals(32));
        expect(i2.height, equals(32));
        expect(i2.numChannels, equals(2));
        i2
          ..setPixelRgb(0, 0, 32, 64, 0)
          ..setPixelRgb(1, 0, 64, 32, 0)
          ..setPixelRgb(0, 1, 58, 52, 0)
          ..setPixelRgb(1, 1, 110, 84, 0);
        expect(i2.getPixel(0, 0), equals([32, 64]));
        expect(i2.getPixel(1, 0), equals([64, 32]));
        expect(i2.getPixel(0, 1), equals([58, 52]));
        expect(i2.getPixel(1, 1), equals([110, 84]));

        await testImageConversions(i2);
      });

      test('nc:3', () async {
        final i3 = Image(width: 32, height: 32, format: Format.uint16);
        expect(i3.width, equals(32));
        expect(i3.height, equals(32));
        expect(i3.numChannels, equals(3));
        i3
          ..setPixelRgb(0, 0, 32, 64, 86)
          ..setPixelRgb(1, 0, 64, 32, 14)
          ..setPixelRgb(0, 1, 58, 52, 5)
          ..setPixelRgb(1, 1, 110, 84, 94);
        expect(i3.getPixel(0, 0), equals([32, 64, 86]));
        expect(i3.getPixel(1, 0), equals([64, 32, 14]));
        expect(i3.getPixel(0, 1), equals([58, 52, 5]));
        expect(i3.getPixel(1, 1), equals([110, 84, 94]));

        for (final p in i3) {
          final c = p.x * 2114;
          p
            ..r = c
            ..g = c
            ..b = c;
          final p2 = i3.getPixel(p.x, p.y);
          expect(p2, [c, c, c]);
        }

        await testImageConversions(i3);
      });

      test('nc:4', () async {
        final i4 =
            Image(width: 32, height: 32, format: Format.uint16, numChannels: 4);
        expect(i4.width, equals(32));
        expect(i4.height, equals(32));
        expect(i4.numChannels, equals(4));
        i4
          ..setPixelRgba(0, 0, 32, 64, 86, 44)
          ..setPixelRgba(1, 0, 64, 32, 14, 14)
          ..setPixelRgba(0, 1, 12, 52, 5, 52)
          ..setPixelRgba(1, 1, 100, 84, 94, 82);
        expect(i4.getPixel(0, 0), equals([32, 64, 86, 44]));
        expect(i4.getPixel(1, 0), equals([64, 32, 14, 14]));
        expect(i4.getPixel(0, 1), equals([12, 52, 5, 52]));
        expect(i4.getPixel(1, 1), equals([100, 84, 94, 82]));

        await testImageConversions(i4);
      });
    });
  });
}
