import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void copyFlipTest() {
  test('copyFlip', () {
    final img = decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

    final ih = copyFlip(img, FlipDirection.horizontal);
    expect(ih.numChannels, equals(ih.numChannels));
    File('$tmpPath/out/transform/copyFlip_h.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(ih));

    final iv = copyFlip(img, FlipDirection.vertical);
    expect(iv.numChannels, equals(ih.numChannels));
    File('$tmpPath/out/transform/copyFlip_v.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(iv));

    final ib = copyFlip(img, FlipDirection.both);
    expect(ib.numChannels, equals(ih.numChannels));
    File('$tmpPath/out/transform/copyFlip_b.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(ib));
  });
}
