import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('filter', () async {
      Command()
        ..decodeGifFile('test/_data/gif/cars.gif')
        ..filter((image) =>
          drawString(image, arial14, 10, 10, '${image.frameIndex}')
        )
        ..writeToFile('$testOutputPath/cmd/cars.gif')
        ..execute();
    });
  });
}
