import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../test_util.dart';

void fillTest() {
  test('fill', () {
    Command()
      ..createImage(256, 256)
      ..fill(ColorRgba8(120, 64, 85, 90))
      ..writeToFile('$testOutputPath/cmd/fill.png')
      ..execute();
  });
}
