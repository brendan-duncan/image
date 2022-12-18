import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void CopyResizeCropSquareTest() {
  test('copyResizeCropSquare', () {
    final img = decodePng(File('test/data/png/buck_24.png').readAsBytesSync())!;
    final i0 = copyResizeCropSquare(img, 64);
    expect(i0.width, equals(64));
    expect(i0.height, equals(64));
    File('$tmpPath/out/transform/copyResizeCropSquare.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
