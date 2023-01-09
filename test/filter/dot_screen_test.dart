import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('dotScreen', () async {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final img = decodePng(bytes)!;
      final i0 = img.clone();
      dotScreen(i0);
      File('$testOutputPath/filter/dotScreen.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
            x: img.width ~/ 2,
            y: img.height ~/ 2,
            radius: 80,
            color: ColorRgb8(255, 255, 255))
        ..gaussianBlur(radius: 20);

      await (Command()
            ..image(img)
            ..copy()
            ..dotScreen(mask: mask)
            ..writeToFile('$testOutputPath/filter/dotScreen_mask.png'))
          .execute();
    });
  });
}
