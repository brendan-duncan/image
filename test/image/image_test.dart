import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Image', () {
    test('empty', () {
      final i0 = Image.empty();
      expect(i0.isValid, equals(false));

      final i1 = Image.empty();
      expect(i1.isValid, equals(false));
    });

    test('rowStride', () {
      for (final format in Format.values) {
        final img = Image(width: 10, height: 1, format: format);
        expect(img.rowStride, getRowStride(10, 3, format));
      }
    });

    test('fromResized', () {
      final i1 = Image(
        width: 20,
        height: 20,
        withPalette: true,
        numChannels: 4,
      );

      i1
        ..addFrame(Image(width: 20, height: 20, palette: i1.palette))
        ..addFrame(Image(width: 20, height: 20, palette: i1.palette));

      for (var i = 0; i < 256; ++i) {
        i1.palette?.setRgba(i, i, i, i, i);
      }

      final i2 = Image.fromResized(i1, width: 10, height: 10);

      for (final img in i2.frames) {
        for (var i = 0; i < 256; ++i) {
          expect(img.palette?.get(i, 0), equals(i));
          expect(img.palette?.get(i, 1), equals(i));
          expect(img.palette?.get(i, 2), equals(i));
          expect(img.palette?.get(i, 3), equals(i));
        }
      }
    });

    test('fromBytes', () {
      const w = 256;
      const h = 256;
      const w2 = 300;
      const stride = w2 * 3;
      final bytes = Uint8List(h * stride);
      for (var y = 0, i = 0; y < h; ++y) {
        for (var x = 0; x < w2; ++x) {
          bytes[i++] = x < 256 ? x : 255;
          bytes[i++] = x < 256 ? y : 0;
          bytes[i++] = x < 256 ? 0 : 255;
        }
      }

      final img = Image.fromBytes(
        width: w,
        height: h,
        bytes: bytes.buffer,
        rowStride: stride,
      );
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(3));
      for (final p in img) {
        expect(p.r, equals(p.x));
        expect(p.g, equals(p.y));
        expect(p.b, equals(0));
      }

      final img2 = Image.fromBytes(
        width: w,
        height: h,
        bytes: bytes.buffer,
        rowStride: stride,
        order: ChannelOrder.bgr,
      );
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(3));
      for (final p in img2) {
        expect(p.r, equals(0));
        expect(p.g, equals(p.y));
        expect(p.b, equals(p.x));
      }

      img2.remapChannels(ChannelOrder.bgr);
      for (final p in img2) {
        expect(p.r, equals(p.x));
        expect(p.g, equals(p.y));
        expect(p.b, equals(0));
      }
    });

    test('fromBytes order', () {
      const w = 256;
      const h = 256;
      const w2 = 300;
      const stride = w2 * 4;
      final bytes = Uint8List(h * stride);
      for (var y = 0, i = 0; y < h; ++y) {
        for (var x = 0; x < w2; ++x) {
          bytes[i++] = 255;
          bytes[i++] = 200;
          bytes[i++] = 128;
          bytes[i++] = 64;
        }
      }

      final img = Image.fromBytes(
        width: 256,
        height: 256,
        bytes: bytes.buffer,
        rowStride: stride,
        order: ChannelOrder.bgra,
      );
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(4));
      for (final p in img) {
        expect(p.r, equals(128));
        expect(p.g, equals(200));
        expect(p.b, equals(255));
        expect(p.a, equals(64));
      }

      img.remapChannels(ChannelOrder.bgra);
      for (final p in img) {
        expect(p.r, equals(255));
        expect(p.g, equals(200));
        expect(p.b, equals(128));
        expect(p.a, equals(64));
      }
    });

    test('fromBytes with a row stride smaller than the image stride', () {
      // Issue #473: a source rowStride smaller than the image's data stride
      // raised a range error because the row copy length was mismatched.
      final bytes = Uint8List.fromList([
        10, 20, 30, 40, 50, 60, // row 0: pixels (0,0) and (1,0)
        70, 80, 90, 100, 110, 120, // row 1: pixels (0,1) and (1,1)
      ]);
      final img = Image.fromBytes(
        width: 4,
        height: 2,
        numChannels: 3,
        bytes: bytes.buffer,
        rowStride: 6,
      );
      expect(img.width, equals(4));
      expect(img.height, equals(2));

      void expectRgb(int x, int y, int r, int g, int b) {
        final p = img.getPixel(x, y);
        expect([p.r, p.g, p.b], equals([r, g, b]));
      }

      expectRgb(0, 0, 10, 20, 30);
      expectRgb(1, 0, 40, 50, 60);
      // Columns past the provided row stride remain zero.
      expectRgb(2, 0, 0, 0, 0);
      expectRgb(0, 1, 70, 80, 90);
      expectRgb(1, 1, 100, 110, 120);
    });

    test('convert applies an explicit alpha', () {
      // Issue #544: convert(alpha:) was ignored when the format and channel
      // count were unchanged.
      final img = Image(width: 8, height: 8, numChannels: 4);
      for (final p in img) {
        p.setRgba(10, 20, 30, 255);
      }

      final faded = img.convert(alpha: 128);
      for (final p in faded) {
        expect([p.r, p.g, p.b, p.a], equals([10, 20, 30, 128]));
      }

      // An image without an alpha channel is unaffected.
      final rgb = Image(width: 4, height: 4)..clear(ColorRgb8(1, 2, 3));
      expect(rgb.convert(alpha: 128).numChannels, equals(3));
    });

    test('getPixel iterator', () {
      final i0 = Image(width: 10, height: 10);
      final p = i0.getPixel(0, 5);
      int x = 0;
      int y = 5;
      do {
        expect(x, equals(p.x));
        expect(y, equals(p.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      } while (p.moveNext());
    });

    test('getRange', () {
      final i0 = Image(width: 10, height: 10);
      int x = 0;
      int y = 0;
      final iter = i0.getRange(0, 0, 10, 10);
      while (iter.moveNext()) {
        expect(x, equals(iter.current.x));
        expect(y, equals(iter.current.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      }
    });

    test('convert', () async {
      final rgba8p =
          Image(width: 256, height: 256, numChannels: 4, withPalette: true)
            ..addFrame(
              Image(width: 256, height: 256, numChannels: 4, withPalette: true),
            );

      for (final frame in rgba8p.frames) {
        for (var pi = 0; pi < frame.palette!.numColors; ++pi) {
          frame.palette!.setRgba(pi, pi, pi, pi, 255);
        }
        for (final p in frame) {
          p.index = ((frame.frameIndex * 10) + p.x) % 255;
        }
      }

      await encodeGifFile('$testOutputPath/image/convert_1.gif', rgba8p);

      final rgba8 = rgba8p.convert(numChannels: 4, alpha: 255);

      expect(rgba8.numFrames, equals(2));
      expect(rgba8.hasPalette, equals(false));
      expect(rgba8.numChannels, equals(4));
      expect(rgba8.frames[1].hasPalette, equals(false));
      expect(rgba8.frames[1].numChannels, equals(4));

      for (final frame in rgba8.frames) {
        for (final p in frame) {
          final v = ((frame.frameIndex * 10) + p.x) % 255;
          expect(p.r, equals(v));
          expect(p.g, equals(v));
          expect(p.b, equals(v));
          expect(p.a, equals(255));
        }
      }
    });

    test('alpha_bmp_1bpp', () async {
      final img = await decodePngFile('test/_data/png/alpha_bmp.png');
      final bg = Image(width: img!.width, height: img.height)
        ..clear(ColorRgb8(255, 255, 255));
      compositeImage(bg, img);
      final bpp1 = bg.convert(format: Format.uint1, numChannels: 1);
      await encodeBmpFile('$testOutputPath/bmp/alpha_bmp_cvt.bmp', bpp1);
    });

    test('GetBytes', () {
      final i1 = Image(width: 10, height: 10)..setPixelRgb(0, 0, 32, 64, 128);
      final b1 = i1.getBytes();
      expect(b1.length, equals(10 * 10 * 3));
      expect(b1[0], equals(32));
      expect(b1[1], equals(64));
      expect(b1[2], equals(128));
    });

    test('GetBytes rgb->argb', () {
      final i1 = Image(width: 1, height: 1)..setPixelRgb(0, 0, 32, 64, 128);
      final b1 = i1.getBytes(order: ChannelOrder.argb);
      expect(b1.length, equals(4));
      expect(b1[0], equals(255));
      expect(b1[1], equals(32));
      expect(b1[2], equals(64));
      expect(b1[3], equals(128));
    });

    test('convert withPalette leaves the source unchanged', () {
      final img = Image(width: 4, height: 1, numChannels: 1);
      for (final p in img) {
        p.r = p.x * 60;
      }
      img.convert(format: Format.uint8, withPalette: true);
      expect(img.toUint8List(), equals([0, 60, 120, 180]));
    });

    test('convert expands uint8 palette to RGB and RGBA', () {
      final opaque = _paletteImage(3);
      final translucent = _paletteImage(4);

      expect(opaque.convert(numChannels: 3).toUint8List(),
          _paletteColors(channels: 3));
      expect(opaque.convert(numChannels: 4).toUint8List(),
          _paletteColors(channels: 4, alpha: 255));
      expect(opaque.convert(numChannels: 4, alpha: 128).toUint8List(),
          _paletteColors(channels: 4, alpha: 128));

      expect(translucent.convert(numChannels: 3).toUint8List(),
          _paletteColors(channels: 3));
      expect(translucent.convert(numChannels: 4).toUint8List(),
          _paletteColors(channels: 4));
    });

    test('convert of uint8 palette to 1 and 2 channels matches RGB source', () {
      for (final paletteChannels in [3, 4]) {
        final indexed = _paletteImage(paletteChannels);
        final direct = Image(width: 16, height: 16, numChannels: 4)
          ..toUint8List().setAll(
              0,
              _paletteColors(
                  channels: 4, alpha: paletteChannels == 3 ? 255 : null));
        final source =
            paletteChannels == 3 ? direct.convert(numChannels: 3) : direct;

        for (final channels in [1, 2]) {
          expect(indexed.convert(numChannels: channels).toUint8List(),
              source.convert(numChannels: channels).toUint8List(),
              reason: '$paletteChannels-channel palette to $channels');
        }
      }
    });

    test('convert uses palette of every animation frame', () {
      final animation = _paletteImage(3)..frameDuration = 80;
      final second = _paletteImage(3)..frameDuration = 90;
      for (var index = 0; index < 256; index++) {
        second.palette!.setRgb(index, 255 - index, index, 7);
      }
      animation.addFrame(second);

      final converted = animation.convert(numChannels: 4);
      final first = converted.frames[0].getPixel(5, 0);
      final last = converted.frames[1].getPixel(5, 0);

      expect([first.r, first.g, first.b, first.a], [5, 250, 35, 255]);
      expect([last.r, last.g, last.b, last.a], [250, 5, 7, 255]);
      expect(converted.frames.map((frame) => frame.frameDuration), [80, 90]);
    });

    test('convert of 16-color palette reads index 16 as black', () {
      final palette = PaletteUint8(16, 3);
      for (var index = 0; index < 16; index++) {
        palette.setRgb(index, 10 + index, 20 + index, 30 + index);
      }

      final image = Image(width: 3, height: 1, palette: palette)
        ..setPixelIndex(0, 0, 3)
        ..setPixelIndex(1, 0, 15)
        ..setPixelIndex(2, 0, 16);

      expect(image.convert(numChannels: 3).toUint8List(),
          [13, 23, 33, 25, 35, 45, 0, 0, 0]);
    });

    for (final name in [
      'gif/animated.gif',
      'gif/anim_palette.gif',
      'gif/palette_remap.gif',
      'gif/buck_24.gif',
      'bmp/buck_8.bmp',
      'bmp/buck_4.bmp',
      'bmp/buck_1.bmp',
      'png/bkgd.png',
      'png/buck_8.png',
      'png/basn3p08.png',
      'png/basn3p02.png',
      'png/tbbn3p08.png',
    ]) {
      test('convert keeps color of every pixel of palette image $name', () {
        final source = decodeTestImage(name);
        expect(source.hasPalette, isTrue);

        final opaque = source.convert(format: Format.uint8, numChannels: 3);
        final translucent =
            source.convert(format: Format.uint8, numChannels: 4);

        expect(translucent.frames.map((frame) => frame.frameDuration),
            source.frames.map((frame) => frame.frameDuration));
        expect(differingPixels(opaque, source, withAlpha: false), 0);
        expect(differingPixels(translucent, source), 0);
      });
    }

    test('convert keeps pixels of palette image after in-place resize', () {
      final source = decodeTestImage('gif/buck_24.gif');
      final shrunk = resize(source, width: 100);
      final converted = shrunk.convert(numChannels: 4);

      expect([converted.width, converted.height], [100, 62]);
      expect(differingPixels(converted, shrunk), 0);
    });

    for (final name in [
      'bmp/buck_1.bmp',
      'bmp/buck_4.bmp',
      'png/basn3p02.png'
    ]) {
      test('pixel alpha of 3-channel palette image $name is opaque', () {
        final source = decodeTestImage(name);
        expect(source.palette!.numChannels, 3);

        for (final pixel in source) {
          if (pixel.a != 255) {
            fail('alpha ${pixel.a} at ${pixel.x},${pixel.y}');
          }
        }
      });
    }

    for (final format in [Format.uint1, Format.uint2, Format.uint4]) {
      test(
          'iteration over ${format.name} image matches getPixel after '
          'in-place resize', () {
        final mismatches = <String>[];
        for (var channels = 1; channels <= 4; channels++) {
          for (var width = 3; width <= 30; width++) {
            final source = Image(
                width: width, height: 6, format: format, numChannels: channels);
            final range = source.maxChannelValue.toInt() + 1;
            for (var y = 0; y < 6; y++) {
              for (var x = 0; x < width; x++) {
                final pixel = source.getPixel(x, y);
                for (var channel = 0; channel < channels; channel++) {
                  pixel[channel] = (x * 5 + y * 3 + channel) % range;
                }
              }
            }

            final shrunk = resize(source, width: 1 + width * 2 ~/ 3, height: 4);
            var isSame = true;
            for (final pixel in shrunk) {
              final direct = shrunk.getPixel(pixel.x, pixel.y);
              for (var channel = 0; channel < channels; channel++) {
                isSame = isSame && pixel[channel] == direct[channel];
              }
            }

            if (!isSame) {
              mismatches.add('$channels channels, width $width');
            }
          }
        }

        expect(mismatches, isEmpty);
      });
    }

    for (final format in [Format.uint1, Format.uint2, Format.uint4]) {
      test('iteration over ${format.name} image matches getPixel', () {
        final mismatches = <String>[];
        for (var channels = 1; channels <= 4; channels++) {
          for (var width = 1; width <= 40; width++) {
            final written = Image(
                width: width, height: 5, format: format, numChannels: channels);
            final range = written.maxChannelValue.toInt() + 1;
            for (final pixel in written) {
              for (var channel = 0; channel < channels; channel++) {
                pixel[channel] = (pixel.x * 7 + pixel.y * 3 + channel) % range;
              }
            }

            var isSame = true;
            for (final pixel in written) {
              final direct = written.getPixel(pixel.x, pixel.y);
              for (var channel = 0; channel < channels; channel++) {
                final expected = (pixel.x * 7 + pixel.y * 3 + channel) % range;
                isSame = isSame &&
                    pixel[channel] == expected &&
                    direct[channel] == expected;
              }
            }

            if (!isSame) {
              mismatches.add('$channels channels, width $width');
            }
          }
        }

        expect(mismatches, isEmpty);
      });
    }

    for (final name in [
      'bmp/buck_1.bmp',
      'png/basn3p02.png',
      'bmp/buck_4.bmp'
    ]) {
      test('iteration over $name matches getPixel after in-place resize', () {
        final source = decodeTestImage(name);
        final expected = copyResize(source, width: source.width * 2 ~/ 3);
        final shrunk = resize(source, width: source.width * 2 ~/ 3);

        expect(identical(shrunk, source), isTrue);
        expect(differingPixels(shrunk, expected), 0);

        final indices = [for (final pixel in shrunk) pixel.index];
        final byPosition = [
          for (var y = 0; y < shrunk.height; y++)
            for (var x = 0; x < shrunk.width; x++) shrunk.getPixelIndex(x, y),
        ];
        expect(indices, byPosition);
      });
    }

    test('float cubic with mixed alpha keeps colors near the taps', () {
      // Mostly transparent with faint pixels: the cubic's negative lobes can
      // leave the blended alpha just above 0, and dividing by it reached
      // colors of 5000 from taps of 0 to 1
      final random = Random(7);
      var worst = 0.0;
      for (var t = 0; t < 300; t++) {
        final image =
            Image(width: 4, height: 4, format: Format.float32, numChannels: 4);
        for (final p in image) {
          p
            ..r = random.nextDouble()
            ..g = random.nextDouble()
            ..b = random.nextDouble()
            ..a = random.nextDouble() < 0.7 ? 0 : random.nextDouble() * 0.05;
        }
        for (var k = 0; k < 20; k++) {
          final c = image.getPixelCubic(
              1 + random.nextDouble(), 1 + random.nextDouble());
          worst =
              max(worst, max(c.r.abs(), max(c.g.abs(), c.b.abs()))).toDouble();
        }
      }
      // Cubic overshoot of uniform alpha stays allowed
      expect(worst, lessThan(1.5));
    });

    for (final format in [Format.uint8, Format.uint16]) {
      test(
          '${format.name} cubic with mixed alpha keeps colors within range '
          'of visible pixels', () {
        final random = Random(7);
        final outside = <String>[];
        for (var round = 0; round < 300; round++) {
          final image =
              Image(width: 4, height: 4, format: format, numChannels: 4);
          final top = image.maxChannelValue.toInt();
          final lowest = top ~/ 2;
          final highest = lowest + top ~/ 8;

          for (final pixel in image) {
            final isHidden = random.nextDouble() < 0.7;
            final alpha = isHidden ? 0 : 1 + random.nextInt(top ~/ 20);
            final color = isHidden
                ? random.nextInt(top + 1)
                : lowest + random.nextInt(top ~/ 8 + 1);

            pixel.setRgba(color, color, color, alpha);
          }

          void verify(Color color) {
            if (color.a > 0 && (color.r < lowest || color.r > highest)) {
              outside.add('round $round: ${color.r} with alpha ${color.a}');
            }
          }

          for (var index = 0; index < 20; index++) {
            verify(image.getPixelCubic(
                1 + random.nextDouble(), 1 + random.nextDouble()));
          }

          copyResize(image, width: 11, interpolation: Interpolation.cubic)
              .forEach(verify);
        }

        expect(outside, isEmpty);
      });
    }

    for (final format in [Format.int8, Format.float32]) {
      test('${format.name} cubic with negative alpha keeps colors finite', () {
        final image =
            Image(width: 4, height: 4, format: format, numChannels: 4);
        for (final pixel in image) {
          pixel.setRgba(10, 10, 10, 0);
        }

        // Only taps in the negative lobes have alpha, so the blended alpha
        // is positive without any tap having positive alpha
        final alpha = format == Format.int8 ? -100 : -0.5;
        image.getPixel(0, 1).a = alpha;
        image.getPixel(0, 2).a = alpha;

        final color = image.getPixelCubic(1.5, 1.5);
        expect(color.a, greaterThan(0));
        expect(color.r, 10);
      });
    }
  });
}

Image _paletteImage(int paletteChannels) {
  final image = Image(
      width: 16, height: 16, numChannels: paletteChannels, withPalette: true);
  for (var index = 0; index < 256; index++) {
    image.palette!
        .setRgba(index, index, 255 - index, index * 7 % 256, index * 13 % 256);
  }

  for (final pixel in image) {
    pixel.index = pixel.y * 16 + pixel.x;
  }

  return image;
}

List<int> _paletteColors({required int channels, int? alpha}) => [
      for (var index = 0; index < 256; index++) ...[
        index,
        255 - index,
        index * 7 % 256,
        if (channels == 4) alpha ?? index * 13 % 256,
      ],
    ];
