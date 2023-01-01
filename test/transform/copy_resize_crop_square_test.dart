import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyResizeCropSquare', () async {
      final i0 = await (Command()
      ..decodePngFile('test/_data/png/buck_24.png')
      ..copyResizeCropSquare(size: 64)
      ..writeToFile('$testOutputPath/transform/copyResizeCropSquare.png'))
      .getImage();
      expect(i0, isNotNull);
      expect(i0!.width, equals(64));
      expect(i0.height, equals(64));

      await (Command()
        ..decodePngFile('test/_data/png/buck_24.png')
        ..copyResizeCropSquare(size: 64, radius: 20)
        ..writeToFile(
            '$testOutputPath/transform/copyResizeCropSquare_rounded.png'))
        .execute();
    });
  });
}
