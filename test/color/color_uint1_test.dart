import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('ColorUint1', () {
      final c0 = ColorUint1(0);
      expect(c0.length, equals(0));
      expect(c0.r, equals(0));
      expect(c0.g, equals(0));
      expect(c0.b, equals(0));
      expect(c0.a, equals(0));

      final c1 = ColorUint1.rgba(1, 0, 1, 1);
      expect(c1.length, equals(4));
      expect(c1.r, equals(1));
      expect(c1.g, equals(0));
      expect(c1.b, equals(1));
      expect(c1.a, equals(1));
    });
  });
}
