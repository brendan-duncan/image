import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawChar', () async {
      final cmd = Command()
          ..createImage(width: 256, height: 256)
          ..fill(ColorRgb8(128, 128))
          ..drawChar(arial24, 50, 50, "H")
          ..drawChar(arial24, 70, 70, "e",
              color: ColorRgba8(255))
          ..drawChar(arial24, 90, 90, "l",
              color: ColorRgba8(0, 255))
          ..drawChar(arial24, 110, 110, "l",
              color: ColorRgba8(0, 0, 255))
          ..drawChar(arial24, 130, 130, "o",
              color: ColorRgba8(255, 0, 0, 128))
          ..writeToFile('$testOutputPath/draw/draw_char.png');

      final image = await cmd.getImageThread();
      expect(image, isNotNull);
      expect(image?.width, equals(256));
      expect(image?.height, equals(256));
    });
  });
}
