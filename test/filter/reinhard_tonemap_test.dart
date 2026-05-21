import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('reinhardTonemap', () async {
      final hdr = (await decodeExrFile('test/_data/exr/ocean.exr'))!;

      reinhardTonemap(hdr);
      final ldr = hdrToLdr(hdr, exposure: -1);

      File('$testOutputPath/filter/reinhardTonemap.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ldr));
    });

    test('reinhardTonemap maps a uniform HDR image to uniform white', () {
      // For a uniform image the per-pixel scale works out to 1/luminance, so
      // every channel maps exactly to 1.0 (white in HDR terms).
      final hdr = Image(width: 8, height: 8, format: Format.float32);
      for (final p in hdr) {
        p.setRgb(0.5, 0.5, 0.5);
      }

      final result = reinhardTonemap(hdr);

      // The tone map mutates and returns the source image.
      expect(identical(result, hdr), isTrue);
      expect(result.width, equals(8));
      expect(result.height, equals(8));
      for (final p in result) {
        expect((p.r - 1.0).abs(), lessThan(0.001),
            reason: 'r at ${p.x},${p.y}');
        expect((p.g - 1.0).abs(), lessThan(0.001),
            reason: 'g at ${p.x},${p.y}');
        expect((p.b - 1.0).abs(), lessThan(0.001),
            reason: 'b at ${p.x},${p.y}');
      }
    });
  });
}
