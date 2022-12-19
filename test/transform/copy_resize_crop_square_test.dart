import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void copyResizeCropSquareTest() {
  test('copyResizeCropSquare', () {
    final img = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;
    final i0 = copyResizeCropSquare(img, 64);
    expect(i0.width, equals(64));
    expect(i0.height, equals(64));
    File('$testOutputPath/transform/copyResizeCropSquare.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
