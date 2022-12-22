import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void cmdTests() {
  group('ImageCommand', () {
    test('fill', () {
      Command()
        ..createImage(256, 256)
        ..fill(ColorRgba8(120, 64, 85, 90))
        ..writeToFile('$testOutputPath/cmd/fill.png')
        ..execute();
    });

    test('forEachFrameCmd', () {
      Command()
          ..decodeGifFile('test/_data/gif/cars.gif')
          ..forEachFrame(Command()..drawString(arial14, 10, 10,
              '${currentFrame?.frameIndex}'))
          ..writeToFile('$testOutputPath/cmd/cars.gif')
          ..execute();
    });
  });
}
