import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('billboard', () async {
      final img = (await decodePngFile('test/_data/png/buck_24.png'))!;
      final i0 = img.clone();
      billboard(i0);
      await encodePngFile('$testOutputPath/filter/billboard.png', i0);

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
            x: img.width ~/ 2,
            y: img.height ~/ 2,
            radius: 50,
            color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 10);

      await (Command()
            ..image(img)
            ..copy()
            ..billboard(mask: mask)
            ..writeToFile('$testOutputPath/filter/billboard_mask.png'))
          .execute();
    });
  });
}
