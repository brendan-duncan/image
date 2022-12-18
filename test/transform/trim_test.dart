import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void TrimTest() {
  test('trim', () {
    final image = decodePng(File('test/data/png/trim.png').readAsBytesSync())!;
    var trimmed = trim(image);
    File('$tmpPath/out/transform/trim.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(trimmed));
    expect(trimmed.width, equals(64));
    expect(trimmed.height, equals(56));

    trimmed = trim(image, mode: TrimMode.topLeftColor);
    File('$tmpPath/out/transform/trim_topLeftColor.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(trimmed));
    expect(trimmed.width, equals(64));
    expect(trimmed.height, equals(56));

    trimmed = trim(image, mode: TrimMode.bottomRightColor);
    File('$tmpPath/out/transform/trim_bottomRightColor.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(trimmed));
    expect(trimmed.width, equals(64));
    expect(trimmed.height, equals(56));
  });
}
