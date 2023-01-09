import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillCircle', () async {
      await (Command()
            ..createImage(width: 256, height: 256, numChannels: 4)
            ..fillCircle(
                x: 128,
                y: 128,
                radius: 100,
                antialias: true,
                color: ColorRgba8(255, 255, 0, 200))
            ..fillCircle(
                x: 128, y: 128, radius: 50, color: ColorRgba8(0, 255, 0, 255))
            ..writeToFile('$testOutputPath/draw/fillCircle.png'))
          .execute();
    });
  });
}
