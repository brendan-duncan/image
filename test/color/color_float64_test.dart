import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('ColorFloat64', () {
      final c0 = ColorFloat64(0);
      expect(c0.length, equals(0));
      c0.r = 5;
      expect(c0.r, equals(0));
      expect(c0.g, equals(0));
      expect(c0.b, equals(0));
      expect(c0.a, equals(1));
    });
  });
}
