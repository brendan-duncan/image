import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('ColorUint4', () {
      final c0 = ColorUint4(0);
      expect(c0.length, equals(0));
      c0.r = 5;
      expect(c0.r, equals(0));
      expect(c0.g, equals(0));
      expect(c0.b, equals(0));
      expect(c0.a, equals(0));

      final c1 = ColorUint4.rgba(15, 1, 15, 8);
      expect(c1.length, equals(4));
      expect(c1.r, equals(15));
      expect(c1.g, equals(1));
      expect(c1.b, equals(15));
      expect(c1.a, equals(8));
    });
  });
}
