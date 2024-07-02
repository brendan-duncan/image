import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('trim', () {
      final image =
          decodePng(File('test/_data/png/trim.png').readAsBytesSync())!;
      var trimmed = trim(image);
      File('$testOutputPath/transform/trim.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));

      trimmed = trim(image, mode: TrimMode.transparent);
      File('$testOutputPath/transform/trim_transparent.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, equals(image.width));
      expect(trimmed.height, equals(image.height));

      trimmed = trim(image, mode: TrimMode.bottomRightColor);
      File('$testOutputPath/transform/trim_bottomRightColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));
    });

    test('trim_issue', () {
      final image =
          decodePng(File('test/_data/png/trim_issue.png').readAsBytesSync())!;
      final trimmed = trim(image, mode: TrimMode.transparent);
      File('$testOutputPath/transform/trim_issue.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, equals(465));
      expect(trimmed.height, equals(150));

      final image2 = decodePng(
          File('test/_data/png/trim_issue_assert.png').readAsBytesSync());
      expect(image2, isNotNull);
      testImageEquals(trimmed, image2!);
    });
  });
}
