import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../test_util.dart';

void forEachFrameTest() {
  test('forEachFrameCmd', () {
    Command()
      ..decodeGifFile('test/_data/gif/cars.gif')
      ..forEachFrame(Command()..filter((image) {
        drawString(image, arial14, 10, 10, '${currentFrame?.frameIndex}');
      }))
      ..writeToFile('$testOutputPath/cmd/cars.gif')
      ..execute();
  });
}
