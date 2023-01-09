import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('createImage', () async {
      await (Command()
            ..createImage(width: 256, height: 256)
            ..filter((image) {
              for (final p in image) {
                p
                  ..r = p.x
                  ..g = p.y;
              }
              return image;
            })
            ..writeToFile('$testOutputPath/cmd/createImage_1.png')
            ..createImage(width: 128, height: 128)
            ..filter((image) {
              for (final p in image) {
                p
                  ..g = p.x
                  ..b = p.y;
              }
              return image;
            })
            ..writeToFile('$testOutputPath/cmd/createImage_2.png'))
          .execute();

      expect(
          File('$testOutputPath/cmd/createImage_1.png').existsSync(), isTrue);
      expect(
          File('$testOutputPath/cmd/createImage_2.png').existsSync(), isTrue);
    });
  });
}
