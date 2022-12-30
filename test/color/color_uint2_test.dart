import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('ColorUint2', () {
      final c0 = ColorUint2(0);
      expect(c0.length, equals(0));
      expect(c0.r, equals(0));
      expect(c0.g, equals(0));
      expect(c0.b, equals(0));
      expect(c0.a, equals(0));

      final c1 = ColorUint2.rgba(2, 1, 3, 2);
      expect(c1.length, equals(4));
      expect(c1.r, equals(2));
      expect(c1.g, equals(1));
      expect(c1.b, equals(3));
      expect(c1.a, equals(2));
    });
  });
}
