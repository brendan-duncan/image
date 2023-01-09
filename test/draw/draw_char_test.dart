import 'package:image/image.dart';
import 'package:test/test.dart';
import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawChar', () async {
      final cmd = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(128, 128, 0))
        ..drawChar("H", font: arial24, x: 50, y: 50)
        ..drawChar("e",
            font: arial24, x: 70, y: 70, color: ColorRgba8(255, 0, 0, 255))
        ..drawChar("l",
            font: arial24, x: 90, y: 90, color: ColorRgba8(0, 255, 0, 255))
        ..drawChar("l",
            font: arial24, x: 110, y: 110, color: ColorRgba8(0, 0, 255, 255))
        ..drawChar("o",
            font: arial24, x: 130, y: 130, color: ColorRgba8(255, 0, 0, 128))
        ..writeToFile('$testOutputPath/draw/drawChar.png');

      final image = await cmd.getImageThread();
      expect(image, isNotNull);
      expect(image?.width, equals(256));
      expect(image?.height, equals(256));
    });
  });
}
