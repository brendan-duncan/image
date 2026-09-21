import 'package:image/image.dart';
import 'package:test/test.dart';

Image _pattern({bool palette = false, int blue = 40}) {
  final image = Image(width: 8, height: 8, withPalette: palette);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      if (palette) {
        final index = y * 8 + x;
        image.palette!.setRgb(index, 10 + x * 20, 10 + y * 20, blue);
        image.setPixelIndex(x, y, index);
      } else {
        image.setPixelRgb(x, y, 10 + x * 20, 10 + y * 20, blue);
      }
    }
  }
  return image;
}

void _expectNearest(Image image, int width, int height, {int blue = 40}) {
  expect(image.width, width);
  expect(image.height, height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      expect([
        pixel.r,
        pixel.g,
        pixel.b
      ], [
        10 + ((x * 8) ~/ width) * 20,
        10 + ((y * 8) ~/ height) * 20,
        blue
      ], reason: 'output pixel ($x, $y)');
    }
  }
}

void main() {
  group('Transform resize overlap', () {
    for (final size in [(16, 4), (4, 16), (16, 3), (3, 16)]) {
      for (final palette in [false, true]) {
        test('${size.$1}x${size.$2}, palette=$palette', () {
          final src = _pattern(palette: palette);
          final data = src.data;
          final dst = resize(src, width: size.$1, height: size.$2);
          _expectNearest(dst, size.$1, size.$2);
          expect(dst.hasPalette, palette);
          expect(identical(src, dst), !palette);
          if (palette) {
            _expectNearest(src, 8, 8);
          } else {
            expect(identical(dst.data, data), isTrue);
          }
        });
      }
    }

    test('preserves every animation frame and its duration', () {
      final src = _pattern()
        ..loopCount = 3
        ..frameDuration = 100
        ..addFrame(_pattern(blue: 200)..frameDuration = 300);
      final dst = resize(src, width: 16, height: 4);
      expect(dst.numFrames, 2);
      expect(dst.loopCount, 3);
      expect(dst.frames.map((f) => f.frameDuration), [100, 300]);
      _expectNearest(dst.frames[0], 16, 4);
      _expectNearest(dst.frames[1], 16, 4, blue: 200);
    });

    for (final interpolation in Interpolation.values) {
      test('preserves constant color with ${interpolation.name}', () {
        final src = Image(width: 8, height: 8)..clear(ColorRgb8(40, 80, 120));
        final dst =
            resize(src, width: 16, height: 3, interpolation: interpolation);
        expect([dst.width, dst.height], [16, 3]);
        for (final pixel in dst) {
          expect([pixel.r, pixel.g, pixel.b], [40, 80, 120]);
        }
        expect([src.width, src.height],
            interpolation == Interpolation.nearest ? [16, 3] : [8, 8]);
      });
    }

    test('mixed-axis nearest reuses buffers and matches both axis mappings',
        () {
      var cases = 0;
      for (var sw = 2; sw <= 10; sw++) {
        for (var sh = 2; sh <= 10; sh++) {
          for (var w = 1; w <= 20; w++) {
            for (var h = 1; h <= 20; h++) {
              if ((w <= sw && h <= sh) || w * h > sw * sh) continue;
              for (final channels in [1, 3, 4]) {
                final src = Image(width: sw, height: sh, numChannels: channels);
                for (final p in src) {
                  p.setRgba(
                      (p.x * 71 + p.y * 19) % 256,
                      (p.x * 13 + p.y * 97) % 256,
                      (p.x * 41 + p.y * 37) % 256,
                      (p.x * 29 + p.y * 53) % 256);
                }
                final expected = copyResize(src, width: w, height: h);
                final original = src.clone();
                final data = src.data;
                final dst = resize(src, width: w, height: h);
                expect(identical(dst, src), isTrue);
                expect(identical(dst.data, data), isTrue);
                expect(dst.getBytes().take(w * h * channels),
                    orderedEquals(expected.getBytes()),
                    reason: '$sw x $sh -> $w x $h, channels=$channels');
                for (final p in dst) {
                  final q = original.getPixel((p.x * sw) ~/ w, (p.y * sh) ~/ h);
                  expect([p.r, p.g, p.b, p.a], [q.r, q.g, q.b, q.a]);
                }
                cases++;
              }
            }
          }
        }
      }
      expect(cases, greaterThan(1000));
    });

    test('mixed-axis nearest keeps copy fallback outside buffer scope', () {
      for (final src in [
        Image(width: 8, height: 8, numChannels: 2),
        Image(width: 8, height: 8, format: Format.uint16),
        _pattern(palette: true),
      ]) {
        final expected = copyResize(src, width: 16, height: 4);
        final dst = resize(src, width: 16, height: 4);
        expect(identical(dst, src), isFalse);
        expect(dst.getBytes(), orderedEquals(expected.getBytes()));
        expect([src.width, src.height], [8, 8]);
      }
      for (final aspect in [false, true]) {
        final src = _pattern();
        final h = aspect ? 4 : 5;
        final expected =
            copyResize(src, width: 16, height: h, maintainAspect: aspect);
        final dst = resize(src, width: 16, height: h, maintainAspect: aspect);
        expect(identical(dst, src), isFalse);
        expect(dst.getBytes(), orderedEquals(expected.getBytes()));
        _expectNearest(src, 8, 8);
      }
    });

    for (final sharedData in [false, true]) {
      for (final kind in ['mixed', 'cubic', 'letterbox']) {
        test('$kind falls back for shared data=$sharedData', () {
          final src = _pattern(),
              b = _pattern(blue: 80),
              c = _pattern(blue: 120);
          final repeated = sharedData ? (_pattern()..data = b.data) : b;
          src
            ..addFrame(b)
            ..addFrame(c)
            ..addFrame(repeated);
          final width = kind == 'mixed'
              ? 16
              : kind == 'cubic'
                  ? 7
                  : 8;
          final height = kind == 'cubic' ? 7 : 4;
          final interpolation =
              kind == 'cubic' ? Interpolation.cubic : Interpolation.nearest;
          final expected = copyResize(src,
              width: width,
              height: height,
              maintainAspect: kind == 'letterbox',
              interpolation: interpolation);
          final before = src.clone();
          final dst = resize(src,
              width: width,
              height: height,
              maintainAspect: kind == 'letterbox',
              interpolation: interpolation);
          expect(identical(dst, src), isFalse);
          for (var i = 0; i < 4; i++) {
            expect(dst.frames[i].getBytes(),
                orderedEquals(expected.frames[i].getBytes()));
            expect(src.frames[i].getBytes(),
                orderedEquals(before.frames[i].getBytes()));
            expect([src.frames[i].width, src.frames[i].height], [8, 8]);
          }
        });
      }
    }

    test('cubic aspect without padding reuses the buffer', () {
      final src = _pattern();
      final data = src.data;
      final expected = copyResize(src,
          width: 7,
          height: 7,
          maintainAspect: true,
          interpolation: Interpolation.cubic);
      final dst = resize(src,
          width: 7,
          height: 7,
          maintainAspect: true,
          interpolation: Interpolation.cubic);
      expect(identical(dst, src), isTrue);
      expect(identical(dst.data, data), isTrue);
      expect(
          dst.getBytes().take(7 * 7 * 3), orderedEquals(expected.getBytes()));
    });

    test('cubic zero offset still falls back for trailing padding', () {
      final src = Image(width: 8, height: 7)..clear(ColorRgb8(30, 60, 90));
      // Content is 7x6 at offset (0, 0); the final row is still padding.
      final expected = copyResize(src,
          width: 7,
          height: 7,
          maintainAspect: true,
          interpolation: Interpolation.cubic);
      final dst = resize(src,
          width: 7,
          height: 7,
          maintainAspect: true,
          interpolation: Interpolation.cubic);
      expect(identical(dst, src), isFalse);
      expect(dst.getBytes(), orderedEquals(expected.getBytes()));
    });

    test('same size and pure downscale retain the existing in-place path', () {
      final src = _pattern();
      expect(identical(resize(src, width: 8, height: 8), src), isTrue);
      final dst = resize(src, width: 4, height: 4);
      expect(identical(dst, src), isTrue);
      _expectNearest(dst, 4, 4);
    });

    test('cubic downscale reads every sample from the original image', () {
      final src = _pattern();
      final originalData = src.data;
      final expected = Image(width: 7, height: 7);
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          expected.setPixel(x, y, src.getPixelCubic(x * (8 / 7), y * (8 / 7)));
        }
      }
      final dst =
          resize(src, width: 7, height: 7, interpolation: Interpolation.cubic);
      expect(
          dst.getBytes().take(7 * 7 * 3), orderedEquals(expected.getBytes()));
      expect(identical(dst, src), isTrue);
      expect(identical(dst.data, originalData), isTrue);
      expect([src.width, src.height], [7, 7]);
    });

    test('buffered cubic matches copyResize across small dimensions', () {
      for (var sw = 1; sw <= 10; sw++) {
        for (var sh = 1; sh <= 10; sh++) {
          for (var w = 1; w <= sw; w++) {
            for (var h = 1; h <= sh; h++) {
              for (var channels = 1; channels <= 4; channels++) {
                final src = Image(width: sw, height: sh, numChannels: channels);
                for (final p in src) {
                  p.setRgba(
                      (p.x * 71 + p.y * 19) % 256,
                      (p.x * 13 + p.y * 97) % 256,
                      (p.x * 41 + p.y * 37) % 256,
                      (p.x * 29 + p.y * 53) % 256);
                }
                final expected = copyResize(src,
                    width: w, height: h, interpolation: Interpolation.cubic);
                final data = src.data;
                final dst = resize(src,
                    width: w, height: h, interpolation: Interpolation.cubic);
                expect(dst.getBytes().take(w * h * channels),
                    orderedEquals(expected.getBytes()),
                    reason: '$sw x $sh -> $w x $h, channels=$channels');
                expect(identical(dst, src), isTrue);
                expect(identical(dst.data, data), isTrue);
              }
            }
          }
        }
      }
    });

    test('buffered cubic preserves animation and uses one buffer per frame',
        () {
      final src = _pattern()
        ..loopCount = 3
        ..frameDuration = 100
        ..addFrame(_pattern(blue: 200)..frameDuration = 300);
      final expected = copyResize(src,
          width: 7, height: 7, interpolation: Interpolation.cubic);
      final data = src.frames.map((f) => f.data).toList();
      final dst =
          resize(src, width: 7, height: 7, interpolation: Interpolation.cubic);
      expect(identical(src, dst), isTrue);
      expect(dst.loopCount, 3);
      expect(dst.frames.map((f) => f.frameDuration), [100, 300]);
      for (var i = 0; i < 2; i++) {
        expect(identical(dst.frames[i].data, data[i]), isTrue);
        expect(dst.frames[i].getBytes().take(7 * 7 * 3),
            orderedEquals(expected.frames[i].getBytes()));
      }
    });

    test('cubic keeps copy fallback for aspect handling and non-uint8', () {
      for (final src in [
        _pattern(),
        Image(width: 8, height: 8, format: Format.uint16)
          ..clear(ColorUint16.rgb(1000, 2000, 3000))
      ]) {
        final aspect = src.format == Format.uint8;
        final expected = copyResize(src,
            width: 7,
            height: 5,
            maintainAspect: aspect,
            interpolation: Interpolation.cubic);
        final dst = resize(src,
            width: 7,
            height: 5,
            maintainAspect: aspect,
            interpolation: Interpolation.cubic);
        expect(identical(dst, src), isFalse);
        expect([src.width, src.height], [8, 8]);
        expect(dst.getBytes(), orderedEquals(expected.getBytes()));
      }
    });

    for (final size in [(8, 4), (4, 8)]) {
      for (final palette in [false, true]) {
        test('nearest letterbox ${size.$1}x${size.$2}, palette=$palette', () {
          final src = _pattern(palette: palette);
          final originalData = src.data;
          final dst = resize(src,
              width: size.$1, height: size.$2, maintainAspect: true);
          final offsetX = (size.$1 - 4) ~/ 2;
          final offsetY = (size.$2 - 4) ~/ 2;
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final p = dst.getPixel(offsetX + x, offsetY + y);
              expect([p.r, p.g, p.b], [10 + x * 40, 10 + y * 40, 40]);
            }
          }
          expect([dst.width, dst.height], [size.$1, size.$2]);
          expect(dst.hasPalette, palette);
          expect(identical(dst, src), !palette);
          if (palette) {
            _expectNearest(src, 8, 8);
          } else {
            expect(identical(dst.data, originalData), isTrue);
          }
        });
      }
    }

    test('in-place nearest letterbox matches all pixels including padding', () {
      var cases = 0;
      for (var sw = 2; sw <= 12; sw++) {
        for (var sh = 2; sh <= 12; sh++) {
          for (var w = 2; w <= sw; w++) {
            for (var h = 2; h <= sh; h++) {
              var cw = w, ch = (w * (sh / sw)).toInt();
              if (ch > h) {
                ch = h;
                cw = (h * (sw / sh)).toInt();
              }
              if (cw == 0 ||
                  ch == 0 ||
                  ((w - cw) ~/ 2 == 0 && (h - ch) ~/ 2 == 0)) {
                continue;
              }
              for (final channels in [1, 3, 4]) {
                final src = Image(width: sw, height: sh, numChannels: channels);
                for (final p in src) {
                  p.setRgba(
                      (p.x * 71 + p.y * 19) % 256,
                      (p.x * 13 + p.y * 97) % 256,
                      (p.x * 41 + p.y * 37) % 256,
                      (p.x * 29 + p.y * 53) % 256);
                }
                final expected =
                    copyResize(src, width: w, height: h, maintainAspect: true);
                final data = src.data;
                final dst =
                    resize(src, width: w, height: h, maintainAspect: true);
                expect(dst.getBytes().take(w * h * channels),
                    orderedEquals(expected.getBytes()),
                    reason: '$sw x $sh -> $w x $h, channels=$channels');
                expect(identical(dst, src), isTrue);
                expect(identical(dst.data, data), isTrue);
                cases++;
              }
            }
          }
        }
      }
      expect(cases, greaterThan(1000));
    });

    test('nearest letterbox preserves animation and frame buffers', () {
      final src = _pattern()
        ..loopCount = 3
        ..frameDuration = 100
        ..addFrame(_pattern(blue: 200)..frameDuration = 300);
      final expected =
          copyResize(src, width: 8, height: 4, maintainAspect: true);
      final data = src.frames.map((f) => f.data).toList();
      final dst = resize(src, width: 8, height: 4, maintainAspect: true);
      expect(identical(src, dst), isTrue);
      expect(dst.loopCount, 3);
      expect(dst.frames.map((f) => f.frameDuration), [100, 300]);
      for (var i = 0; i < 2; i++) {
        expect(identical(dst.frames[i].data, data[i]), isTrue);
        expect(dst.frames[i].getBytes().take(8 * 4 * 3),
            orderedEquals(expected.frames[i].getBytes()));
      }
    });

    test('nearest letterbox keeps background and format fallbacks', () {
      for (final src in [
        _pattern(),
        Image(width: 8, height: 8, numChannels: 2)
          ..clear(ColorRgb8(40, 80, 120)),
        Image(width: 8, height: 8, format: Format.uint16)
          ..clear(ColorUint16.rgb(1000, 2000, 3000))
      ]) {
        final bg = src.format == Format.uint8 && src.numChannels == 3
            ? ColorRgb8(3, 5, 7)
            : null;
        final expected = copyResize(src,
            width: 8, height: 4, maintainAspect: true, backgroundColor: bg);
        final dst = resize(src,
            width: 8, height: 4, maintainAspect: true, backgroundColor: bg);
        expect(identical(dst, src), isFalse);
        expect([src.width, src.height], [8, 8]);
        expect(dst.getBytes(), orderedEquals(expected.getBytes()));
      }
    });

    for (final interpolation in Interpolation.values) {
      test('mixed axes match copyResize with ${interpolation.name}', () {
        final src = _pattern();
        final expected =
            copyResize(src, width: 16, height: 3, interpolation: interpolation);
        final dst =
            resize(src, width: 16, height: 3, interpolation: interpolation);
        expect(dst.getBytes().take(16 * 3 * 3),
            orderedEquals(expected.getBytes()));
        if (interpolation != Interpolation.nearest) {
          _expectNearest(src, 8, 8);
        }
      });
    }

    test('mixed axes preserve letterbox content and background', () {
      final src = _pattern();
      final dst = resize(src,
          width: 16,
          height: 4,
          maintainAspect: true,
          backgroundColor: ColorRgb8(3, 5, 7));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 16; x++) {
          final p = dst.getPixel(x, y);
          expect(
              [p.r, p.g, p.b],
              x >= 6 && x < 10
                  ? [10 + (x - 6) * 40, 10 + y * 40, 40]
                  : [3, 5, 7]);
        }
      }
      _expectNearest(src, 8, 8);
    });
    // (source width, source height, width, height): leading offsets and
    // trailing-only padding on each axis.
    for (final c in [(8, 8, 8, 4), (8, 8, 4, 8), (8, 7, 7, 7), (7, 8, 7, 7)]) {
      for (final interpolation in Interpolation.values) {
        for (final background in [null, ColorRgb8(1, 2, 3)]) {
          test(
              'letterbox ${c.$1}x${c.$2} -> ${c.$3}x${c.$4} matches copyResize'
              ' with ${interpolation.name}, background=${background != null}',
              () {
            final src = Image(width: c.$1, height: c.$2);
            for (final p in src) {
              p.setRgb(10 + p.x * 20, 10 + p.y * 20, 40 + p.x * p.y);
            }
            final expected = copyResize(src,
                width: c.$3,
                height: c.$4,
                maintainAspect: true,
                backgroundColor: background,
                interpolation: interpolation);
            final dst = resize(src,
                width: c.$3,
                height: c.$4,
                maintainAspect: true,
                backgroundColor: background,
                interpolation: interpolation);
            expect([dst.width, dst.height], [c.$3, c.$4]);
            expect(dst.getBytes().take(c.$3 * c.$4 * 3),
                orderedEquals(expected.getBytes()));
          });
        }
      }
    }
  });
}
