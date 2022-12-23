import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../test_util.dart';

void filterTest() {
  test('filter', () {
    Command()
      ..decodeGifFile('test/_data/gif/cars.gif')
      //..forEachFrame(Command()..filter((image) {
      ..filter((image) =>
        drawString(image, arial14, 10, 10, '${image.frameIndex}')
      )//)
      ..writeToFile('$testOutputPath/cmd/cars.gif')
      ..execute();
  });
}
