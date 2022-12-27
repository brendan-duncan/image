import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('dropShadow', () {
      final i0 = Image(width: 256, height: 256, numChannels: 4);
      drawStringCentered(i0, arial48, 'Shadow', color: ColorRgb8(255));

      final id = dropShadow(i0, -5, 5, 3);

      final i1 = Image(width: 256, height: 256)
      ..clear(ColorRgb8(255, 255, 255));
      drawImage(i1, id);

      File('$testOutputPath/filter/dropShadow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });
  });
}
