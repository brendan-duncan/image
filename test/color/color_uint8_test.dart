import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('ColorUint8', () {
      final c0 = ColorUint8(0);
      expect(c0.length, equals(0));
      c0.r = 5;
      expect(c0.r, equals(0));
      expect(c0.g, equals(0));
      expect(c0.b, equals(0));
      expect(c0.a, equals(255));

      final c3 = ColorUint8.rgb(5, 12, 230);
      expect(c3.length, equals(3));
      expect(c3.r, equals(5));
      expect(c3.g, equals(12));
      expect(c3.b, equals(230));
      expect(c3.a, equals(255));
      c3.g = 10;
      expect(c3.g, equals(10));

      final c4 = ColorUint8.rgba(5, 12, 230, 240);
      expect(c4.length, equals(4));
      expect(c4.r, equals(5));
      expect(c4.g, equals(12));
      expect(c4.b, equals(230));
      expect(c4.a, equals(240));

      c3.set(c4);
      expect(c3.r, equals(5));
      expect(c3.g, equals(12));
      expect(c3.b, equals(230));

      num sum = 0;
      for (var c in c4) {
        sum += c;
      }
      expect(sum, equals(5 + 12 + 230 + 240));

      c4.a = 255;
      final a = c4.a / c4.maxChannelValue;
      expect(a, equals(1.0));
    });

    test('ColorUint8.equality', () {
      final ca = ColorUint8.rgba(5, 10, 123, 40);
      final cb = ColorUint8.rgba(3, 10, 123, 40);
      expect(ca == cb, equals(false));
      expect(ca != cb, equals(true));

      cb.r = 5;
      expect(ca == cb, equals(true));
      expect(ca != cb, equals(false));
    });
  });
}
