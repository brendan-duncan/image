import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('reinhardTonemap', () async {
      final hdr = (await decodeExrFile('test/_data/exr/ocean.exr'))!;
      final orig = hdr.clone();

      reinhardTonemap(hdr);
      final ldr = hdrToLdr(hdr, exposure: -1);

      File('$testOutputPath/filter/reinhardTonemap.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ldr));

      expect(ldr.width, equals(orig.width));
      expect(ldr.height, equals(orig.height));
      expect(hdr.format, equals(orig.format));

      // Each pixel's luminance L is scaled to Ls = L * 0.18 / La, where La is
      // the log-average luminance of the image, then mapped to
      // Ls * (1 + Ls / Lwhite^2) / (1 + Ls), where Lwhite is the largest Ls.
      num lum(Pixel p) => 0.212671 * p.r + 0.715160 * p.g + 0.072169 * p.b;
      var logSum = 0.0;
      var maxLum = 0.0;
      for (final p in orig) {
        final l = lum(p);
        if (l > 1.0e-4) {
          logSum += log(l);
        }
        maxLum = max(maxLum, l.toDouble());
      }
      final la = exp(logSum / (orig.width * orig.height));
      final k = 0.18 / la;
      final white = maxLum * k;
      for (final p in hdr) {
        final o = orig.getPixel(p.x, p.y);
        final l = lum(o) * k;
        final s = k * (1 + l / (white * white)) / (1 + l);
        for (var c = 0; c < 3; ++c) {
          final e = o[c] * s;
          expect(p[c], closeTo(e, e.abs() * 2e-3 + 1e-4),
              reason: 'channel $c at ${p.x},${p.y}');
        }
      }
    });

    test('reinhardTonemap maps a uniform HDR image to uniform white', () {
      // For a uniform image every pixel has the largest luminance, which
      // maps to white, so every channel maps exactly to 1.0.
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
