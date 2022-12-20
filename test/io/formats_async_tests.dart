import 'dart:io';

import 'package:image/image_io.dart';
import 'package:test/test.dart';

import '../test_util.dart';

Future<void> formatAsyncTests() async {
  group('formatAsync', () {
    test('decodeJpgFileAsync', () async {
      final i0 = await decodeJpgFileAsync('test/_data/jpg/buck_24.jpg');
      expect(i0, isNotNull);
      expect(i0!.width, equals(300));
      expect(i0.height, equals(186));
      File('$testOutputPath/jpg/decode.png')
        ..createSync(recursive: true)
        ..writeAsBytes(await encodeJpgAsync(i0));
    });
  });
}
