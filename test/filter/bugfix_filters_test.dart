import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

Image _pattern(int width, int height) {
  final img = Image(width: width, height: height);
  for (final p in img) {
    p.setRgb((p.x * 37 + p.y * 11) % 256, (p.x * 5 + p.y * 53) % 256,
        (p.x * p.y) % 256);
  }
  return img;
}

void main() {
  group('Filter bug fixes', () {
    test('contrast scurve applies the scurve table', () {
      // Runs first in this file, so no table has been computed yet.
      final src = horizontalGradient(256, 1);
      final result =
          contrast(src.clone(), contrast: 150, mode: ContrastMode.scurve);
      const c = 1.5 - 0.12;
      for (final p in result) {
        final i = src.getPixel(p.x, p.y).r;
        final e = (((tan(((i / 128) - 1) * c) + 1.0) / 2.0) * 255.0)
            .clamp(0, 255)
            .toInt();
        expect(p.r, equals(e), reason: 'at ${p.x}');
      }
    });

    test('contrast table is keyed on the mode', () {
      final src = horizontalGradient(256, 1);
      final proportional = contrast(src.clone(), contrast: 70);
      final scurve =
          contrast(src.clone(), contrast: 70, mode: ContrastMode.scurve);
      final proportional2 = contrast(src.clone(), contrast: 70);
      expect(imagesAreEqual(proportional, scurve), isFalse);
      testImageEquals(proportional, proportional2);
    });

    test('luminanceThreshold outputColor keeps blue', () {
      final src = solidImage(2, 2, ColorRgb8(250, 250, 100));
      luminanceThreshold(src, outputColor: true);
      expectSolidColor(src, ColorRgb8(250, 250, 100));
    });

    test('hexagonPixelate center offsets the grid in pixels', () {
      final a = _pattern(64, 48);
      // b is a shifted right by 3 and down by 2 pixels.
      final b = Image(width: 64, height: 48);
      for (final p in b) {
        p.set(a.getPixel((p.x - 3) % 64, (p.y - 2) % 48));
      }
      final ha = hexagonPixelate(a.clone(), centerX: 20, centerY: 10);
      final hb = hexagonPixelate(b.clone(), centerX: 23, centerY: 12);
      for (var y = 10; y < 38; ++y) {
        for (var x = 10; x < 54; ++x) {
          expect(hb.getPixel(x + 3, y + 2), equals(ha.getPixel(x, y)),
              reason: 'at $x,$y');
        }
      }
    });

    test('hexagonPixelate handles a single row or column', () {
      final row = _pattern(16, 1);
      hexagonPixelate(row);
      final col = _pattern(1, 16);
      hexagonPixelate(col);
    });

    test('copyImageChannels with a mask mixes normalized values', () {
      final src = solidImage(4, 4, ColorRgb8(100, 100, 100));
      final from = solidImage(4, 4, ColorRgb8(200, 200, 200));
      final mask = solidImage(4, 4, ColorRgb8(128, 128, 128));
      copyImageChannels(src, from: from, red: Channel.red, mask: mask);
      for (final p in src) {
        expect(p.r, closeTo(150, 1));
        expect(p.g, equals(100));
        expect(p.b, equals(100));
      }
    });

    test('pixelate average uses the original block pixels', () {
      final src = _pattern(8, 8);
      final result = pixelate(src.clone(), size: 4, mode: PixelateMode.average);
      for (var by = 0; by < 8; by += 4) {
        for (var bx = 0; bx < 8; bx += 4) {
          final sum = [0, 0, 0];
          for (var y = by; y < by + 4; ++y) {
            for (var x = bx; x < bx + 4; ++x) {
              final o = src.getPixel(x, y);
              for (var c = 0; c < 3; ++c) {
                sum[c] += o[c].toInt();
              }
            }
          }
          for (var y = by; y < by + 4; ++y) {
            for (var x = bx; x < bx + 4; ++x) {
              final p = result.getPixel(x, y);
              for (var c = 0; c < 3; ++c) {
                expect(p[c], equals((sum[c] / 16).floor()),
                    reason: 'channel $c at $x,$y');
              }
            }
          }
        }
      }
    });

    test('pixelate average partial edge blocks keep their color', () {
      final color = ColorRgba8(100, 150, 200, 255);
      final src = solidImage(6, 6, color, numChannels: 4);
      pixelate(src, size: 4, mode: PixelateMode.average);
      expectSolidColor(src, color);
    });

    test('reinhardTonemap compresses luminance into 0-1', () {
      final hdr = Image(width: 16, height: 16, format: Format.float32);
      for (final p in hdr) {
        final v = 0.01 * pow(1.06, p.y * 16 + p.x);
        p.setRgb(v, v, v);
      }
      final maxV = 0.01 * pow(1.06, 255);
      reinhardTonemap(hdr);
      var prev = -1.0;
      for (final p in hdr) {
        expect(p.r, lessThanOrEqualTo(1.0 + 1e-5));
        expect(p.r, greaterThan(prev));
        prev = p.r.toDouble();
      }
      // The brightest pixel maps to white.
      expect(hdr.getPixel(15, 15).r, closeTo(1.0, 1e-5));
      expect(maxV, greaterThan(1));
    });
  });
}
