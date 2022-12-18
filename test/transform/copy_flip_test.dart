import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void CopyFlipTest() {
  test('copyFlip', () {
    final img = decodePng(File('test/data/png/buck_24.png').readAsBytesSync())!;

    final i_h = copyFlip(img, FlipDirection.horizontal);
    expect(i_h.numChannels, equals(i_h.numChannels));
    File('$tmpPath/out/transform/copyFlip_h.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i_h));

    final i_v = copyFlip(img, FlipDirection.vertical);
    expect(i_v.numChannels, equals(i_h.numChannels));
    File('$tmpPath/out/transform/copyFlip_v.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i_v));

    final i_b = copyFlip(img, FlipDirection.both);
    expect(i_b.numChannels, equals(i_h.numChannels));
    File('$tmpPath/out/transform/copyFlip_b.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i_b));
  });
}
