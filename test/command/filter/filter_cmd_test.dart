import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('filter', () async {
      Command()
        ..decodeGifFile('test/_data/gif/cars.gif')
        ..filter((image) => drawString(image, '${image.frameIndex}',
            font: arial14, x: 10, y: 10))
        ..writeToFile('$testOutputPath/cmd/cars.gif')
        ..execute();
    });
  });
}
