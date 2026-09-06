// Encoder behaviour that has to hold on the web as well as on the VM.
//
// Kept apart from `webp_test.dart` because that one reads files, and so cannot
// run in a browser. Everything here is synthetic, so this file runs under
//
//     dart test -p chrome test/formats/webp_web_test.dart
//     dart test -p chrome -c dart2wasm test/formats/webp_web_test.dart
//
// as well as in the normal suite. Doing that matters: under dart2js a Dart int
// is a double, `<<` is a 32-bit shift, and `>>` returns its result *unsigned*,
// so `-5 >> 1` is 4294967293 rather than -3. The lossy encoder once compiled
// cleanly for the web and produced 8 dB where it should have produced 34,
// because every transform shifts signed intermediates. `dart analyze` was
// clean, the whole VM suite passed, and `dart compile js` succeeded.
//
// dart2wasm has real 64-bit integers and behaves like the VM, so it is a third
// case rather than a repeat of the second.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:image/src/formats/webp/vp8_rd.dart';
import 'package:image/src/formats/webp/vp8_sar.dart';
import 'package:image/src/formats/webp/vp8l_color_cache_encoder.dart';
import 'package:image/src/formats/webp/vp8l_color_hash.dart';
import 'package:test/test.dart';

/// A picture with a gradient, an edge, noise and a flat corner, so that every
/// prediction mode and both the flat and busy paths are reached.
///
/// The generator is Park-Miller: the usual LCG multiplier overflows 2^53 on
/// the web, which would quietly make this a different picture there.
Image _scene(int w, int h, {bool alpha = false}) {
  final image = Image(width: w, height: h, numChannels: alpha ? 4 : 3);
  var s = 7;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      s = (s * 16807) % 2147483647;
      final noise = (s >> 16) & 15;
      final flat = x > w * 3 ~/ 4 && y > h * 3 ~/ 4;
      image.getPixel(x, y)
        ..r = flat ? 128 : (x * 3 + noise + (x > w ~/ 2 ? 60 : 0)) & 0xff
        ..g = flat ? 128 : (y * 5 + noise) & 0xff
        ..b = flat ? 128 : (200 - x) & 0xff
        ..a = alpha ? ((x + y) % 5 == 0 ? 0 : (x * 7) & 0xff) : 255;
    }
  }
  return image;
}

/// Fidelity over the visible pixels.
///
/// A fully transparent pixel shows nothing, and both the encoder's default and
/// the animation decoder's compositing are free to put anything under one, so
/// including them would measure those rather than the coding.
double _psnr(Image a, Image b) {
  var sse = 0.0;
  var n = 0;
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      final p = a.getPixel(x, y);
      final q = b.getPixel(x, y);
      if (p.a == 0) {
        continue;
      }
      final dr = p.r - q.r;
      final dg = p.g - q.g;
      final db = p.b - q.b;
      sse += dr * dr + dg * dg + db * db;
      n += 3;
    }
  }
  final mse = sse / n;
  return mse <= 0 ? 99 : 10 * (math.log(65025 / mse) / math.ln10);
}

void main() {
  group('WebP on any platform', () {
    test('the integer arithmetic the encoder relies on', () {
      // Two invariants that hold by construction on the VM and are easy to
      // break for the web. They are cheap, and when this file runs in a
      // browser they say exactly what went wrong rather than leaving a
      // mysterious drop in quality.
      expect(maxCost, equals(1125899906842624),
          reason: 'written as 1 << 50 this is zero on the web, and a zero '
              'ceiling makes the mode search return no mode at all');
      for (final v in [-20091000, -1812, -9, -8, -7, -5, -1, 0, 5, 20091000]) {
        for (final n in [1, 2, 3, 4, 9, 16]) {
          expect(sar(v, n), equals((v / (1 << n)).floor()),
              reason: 'sar($v, $n) must be an arithmetic shift; the plain '
                  'operator returns an unsigned result on the web');
        }
      }
    });

    test('lossy round-trips at every size, method and quality', () {
      // The sizes stress the macroblock geometry: below one macroblock,
      // exactly one, one plus a sliver, and an odd chroma edge.
      for (final size in const [
        [1, 1],
        [15, 15],
        [16, 16],
        [17, 33],
        [40, 24],
        [64, 48],
      ]) {
        final source = _scene(size[0], size[1]);
        for (final method in const [0, 2, 4, 6]) {
          for (final quality in const [30, 75, 98]) {
            final bytes = encodeWebP(source,
                lossless: false, quality: quality, method: method);
            final decoded = decodeWebP(bytes);
            final what = '${size[0]}x${size[1]} m$method q$quality';
            expect(decoded, isNotNull, reason: what);
            // A broken shift or a collapsed score ceiling shows up here as a
            // drop to single digits, not as a crash.
            expect(_psnr(source, decoded!), greaterThan(25), reason: what);
          }
        }
      }
    });

    test('quality still buys fidelity', () {
      // Ordering, not absolute numbers: it holds on any platform, and breaks
      // as soon as the search stops choosing sensibly.
      final source = _scene(48, 48);
      final low = decodeWebP(encodeWebP(source, lossless: false, quality: 20))!;
      final high =
          decodeWebP(encodeWebP(source, lossless: false, quality: 95))!;
      expect(_psnr(source, low), lessThan(_psnr(source, high)));
    });

    test('animation carries every frame, lossless and lossy', () {
      // Nothing covered animated lossy before: each frame gets its own
      // bitstream and, when it has transparency, its own alpha chunk, so this
      // is a different path from the single-image one.
      //
      // Alpha is binary here on purpose. The decoder composites an animated
      // frame onto the canvas, which changes the colour of a partly
      // transparent pixel, so comparing those would measure compositing rather
      // than coding.
      Image animation({required bool alpha}) {
        Image at(int i) {
          final f = Image(width: 48, height: 32, numChannels: alpha ? 4 : 3);
          var s = 7 + i;
          for (var y = 0; y < 32; y++) {
            for (var x = 0; x < 48; x++) {
              s = (s * 16807) % 2147483647;
              final n = (s >> 16) & 15;
              f.getPixel(x, y)
                ..r = (x * 3 + n + i * 20) & 0xff
                ..g = (y * 5 + n) & 0xff
                ..b = (200 - x + i * 10) & 0xff
                ..a = alpha ? ((x + y + i) % 5 == 0 ? 0 : 255) : 255;
            }
          }
          return f..frameDuration = 100;
        }

        final first = at(0);
        for (var i = 1; i < 4; i++) {
          first.addFrame(at(i));
        }
        return first;
      }

      for (final alpha in const [false, true]) {
        final source = animation(alpha: alpha);
        for (final lossless in const [true, false]) {
          final what = 'alpha=$alpha lossless=$lossless';
          final decoded = decodeWebP(encodeWebP(source, lossless: lossless));
          expect(decoded, isNotNull, reason: what);
          expect(decoded!.numFrames, equals(source.numFrames), reason: what);
          for (var i = 0; i < source.numFrames; i++) {
            expect(decoded.frames[i].frameDuration, equals(100),
                reason: '$what frame $i duration');
            // Every frame must be its own picture: an encoder that wrote the
            // first one four times would still decode and still have four
            // frames.
            expect(_psnr(source.frames[i], decoded.frames[i]),
                greaterThan(lossless ? 98 : 25),
                reason: '$what frame $i');
            if (alpha) {
              for (var y = 0; y < 32; y++) {
                for (var x = 0; x < 48; x++) {
                  expect(decoded.frames[i].getPixel(x, y).a,
                      equals(source.frames[i].getPixel(x, y).a),
                      reason: '$what frame $i alpha at $x,$y');
                }
              }
            }
          }
        }
      }
    });

    test('lossless is exact, and so is alpha at any lossy quality', () {
      for (final size in const [
        [1, 1],
        [15, 15],
        [40, 24],
      ]) {
        final source = _scene(size[0], size[1], alpha: true);
        final what = '${size[0]}x${size[1]}';

        // Named rather than left to the default, since this test is about
        // exact: true and not about what the default happens to be
        // ignore: avoid_redundant_argument_values
        final lossless = decodeWebP(encodeWebP(source, exact: true))!;
        for (var y = 0; y < source.height; y++) {
          for (var x = 0; x < source.width; x++) {
            expect(lossless.getPixel(x, y), equals(source.getPixel(x, y)),
                reason: '$what lossless at $x,$y');
          }
        }

        // Alpha rides in its own losslessly coded chunk, so it survives
        // whatever the lossy quality is.
        for (final quality in const [10, 75, 98]) {
          final decoded = decodeWebP(
              encodeWebP(source, lossless: false, quality: quality))!;
          for (var y = 0; y < source.height; y++) {
            for (var x = 0; x < source.width; x++) {
              expect(decoded.getPixel(x, y).a, equals(source.getPixel(x, y).a),
                  reason: '$what alpha at $x,$y, quality $quality');
            }
          }
        }
      }
    });
  });

  group('color cache', () {
    // The cache is addressed by `argb * 0x1e35a7bd`, a product that reaches
    // 2^62 and so is rounded on dart2js, landing on the neighbouring slot for
    // a few colors in every million. The VM cannot see it, and neither can a
    // round-trip: the decoder hashes the same way, so the package agrees with
    // itself while every conforming reader disagrees.
    //
    // These are colors where the two multiplies differ. The keys are exact.
    const divergent = {
      0xff00ea08: [63, 255],
      0xff0aeeed: [169, 679],
      0xff01d410: [60, 243],
    };

    test('a color hashes to the same slot on every platform', () {
      divergent.forEach((argb, keys) {
        expect(colorCacheKey(argb, 24), equals(keys[0]),
            reason: '${argb.toRadixString(16)} at 8 cache bits');
        expect(colorCacheKey(argb, 22), equals(keys[1]),
            reason: '${argb.toRadixString(16)} at 10 cache bits');
      });
    });

    test('the slot the encoder writes is the slot the format defines', () {
      // A repeating palette, which is what makes a cache pay for itself, with
      // one of the divergent colors in it. All literals, so the second
      // occurrence of a color is a cache reference.
      const target = 0xff00ea08;
      const palette = 512;
      const n = 8192;
      final a = Uint8List(n);
      final r = Uint8List(n);
      final g = Uint8List(n);
      final b = Uint8List(n);
      for (var i = 0; i < n; i++) {
        final j = i % palette;
        // Two in a row, so the reference does not depend on what else landed
        // in the slot meanwhile.
        if (j < 2) {
          a[i] = (target >> 24) & 0xff;
          r[i] = (target >> 16) & 0xff;
          g[i] = (target >> 8) & 0xff;
          b[i] = target & 0xff;
        } else {
          a[i] = 0xff;
          r[i] = (j * 7) & 0xff;
          g[i] = (j * 29) & 0xff;
          b[i] = (j * 53) & 0xff;
        }
      }

      final isLiteral = Uint8List(n)..fillRange(0, n, 1);
      final literalIndex = Int32List(n);
      for (var i = 0; i < n; i++) {
        literalIndex[i] = i;
      }
      final keys = Int32List(n);
      final bits = selectColorCacheBits(r, g, b, a, isLiteral, literalIndex,
          Int32List(0), Int32List(0), 64, keys);
      expect(bits, equals(10), reason: 'the palette should earn a cache');

      // The stream carries this number and the decoder answers from the slot
      // its own hash names. 255 is the slot the format defines here; a rounded
      // multiply writes 256, and the reader hands back whatever sits there.
      expect(keys[1], equals(255));
      expect(keys[1], equals(colorCacheKey(target, 32 - bits)));
    });
  });
}
