import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void copyResizeTest() {
  test('copyResize', () {
    final img = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
    final i0 = copyResize(img, width: 64);
    expect(i0.width, equals(64));
    expect(i0.height, equals(39));
    File('$testOutputPath/transform/copyResize.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
