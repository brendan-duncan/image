import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('bmp', () async {
      /*await (Command()
        ..decodeBmpFile('test/_data/bmp/buck_24.bmp')
        ..writeToFile('$testOutputPath/cmd/buck_24.bmp'))
        .execute();
      expect(File('$testOutputPath/cmd/buck_24.bmp').existsSync(), isTrue);*/

      await (Command()
        ..createImage(width: 256, height: 256, format: Format.uint4,
            numChannels: 4)
        ..filter((image) {
          for (final p in image) {
            p..r = p.x ~/ p.maxChannelValue
            ..g = p.y ~/ p.maxChannelValue
            ..a = p.maxChannelValue - (p.y ~/ p.maxChannelValue);
          }
          return image;
        })
        ..writeToFile('$testOutputPath/cmd/bmp_16.bmp')
        ..writeToFile('$testOutputPath/cmd/bmp_16.png'))
        .execute();
    });
  });
}
