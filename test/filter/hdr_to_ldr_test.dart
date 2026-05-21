import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('hdrToLdr', () async {
      final hdr = (await decodeExrFile('test/_data/exr/ocean.exr'))!;

      final ldr = hdrToLdr(hdr, exposure: -1);

      File('$testOutputPath/filter/hdrToLdr.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ldr));

      // The low dynamic range result keeps the source dimensions and channels.
      expect(ldr.width, equals(hdr.width));
      expect(ldr.height, equals(hdr.height));
      expect(ldr.numChannels, equals(hdr.numChannels));
      expect(ldr.format, equals(Format.uint8));
    });

    test('hdrToLdr maps a black HDR image to black', () {
      // A float-format image initializes to all zeros.
      final hdr = Image(width: 8, height: 8, format: Format.float32);
      expectSolidColor(hdrToLdr(hdr), ColorRgb8(0, 0, 0));
    });

    test('hdrToLdr clamps over-bright HDR values to white', () {
      final hdr = Image(width: 8, height: 8, format: Format.float32);
      // Values well above 1.0 must clamp into the LDR [0, 255] range.
      for (final p in hdr) {
        p.setRgb(8, 8, 8);
      }
      expectSolidColor(hdrToLdr(hdr), ColorRgb8(255, 255, 255));
    });
  });
}
