// The alphaQuality test passes the default value explicitly: what that
// default does is the thing under test.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:image/src/formats/webp/vp8_alpha.dart';
import 'package:image/src/formats/webp/vp8_config.dart';
import 'package:image/src/formats/webp/vp8_rd.dart';
import 'package:image/src/formats/webp/vp8_sar.dart';
import 'package:image/src/formats/webp/vp8_state.dart';
import 'package:image/src/formats/webp/vp8_yuv.dart';
import 'package:image/src/formats/webp/vp8l_analysis.dart';
import 'package:image/src/formats/webp/vp8l_backward_refs.dart';
import 'package:image/src/formats/webp/vp8l_bit_writer.dart';
import 'package:image/src/formats/webp/vp8l_encoder.dart';
import 'package:image/src/formats/webp/vp8l_huffman_encoder.dart';
import 'package:image/src/formats/webp/vp8l_optimal_parse.dart';
import 'package:image/src/formats/webp/vp8l_predictor.dart';
import 'package:image/src/formats/webp/webp_container.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    const path = 'test/_data/webp';

    test('webp invalid decode', () async {
      final webp =
          decodeWebP(File('$path/invalid_last_row.webp').readAsBytesSync());
      expect(webp, isNotNull);
      expect(webp!.getPixel(0, webp.height - 2).a, isNot(0));
      // guard against bug where the last decoded row is empty
      expect(webp.getPixel(0, webp.height - 1).a, isNot(0));
    });

    const files = [
      'error2',
      'fig_sharp',
      'fig_noisy',
      'dem',
      'error',
      '1_webp_ll',
      '1_webp_a',
      '2_webp_ll',
      '2_webp_a',
      '3_webp_ll',
      '3_webp_a',
      '4_webp_ll',
      '4_webp_a',
      '5_webp_ll',
      '5_webp_a',
      'test',
    ];

    group('decode webp', () {
      for (var file in files) {
        test(file, () async {
          final webp = decodeWebP(File('$path/$file.webp').readAsBytesSync());
          expect(webp, isNotNull);
          File('$testOutputPath/webp/$file.webp')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodeWebP(webp!));
          if (File('$path/$file.png').existsSync()) {
            final png = decodePng(File('$path/$file.png').readAsBytesSync())!;
            final png4 = png.numChannels != 4
                ? png.convert(numChannels: 4, alpha: 255)
                : png;
            testImageEquals(webp, png4);
          }
        });
      }
    });

    group('webp', () {
      test('exif', () async {
        final webp = await decodeWebPFile('test/_data/webp/buck_24.webp');
        expect(webp, isNotNull);
        expect(webp!.exif.imageIfd['Orientation'], IfdValueShort(1));
      });

      test('animated_lossy', () async {
        final anim = await decodeWebPFile(
          'test/_data/webp/animated_lossy.webp',
        );
        expect(anim, isNotNull);
        for (final frame in anim!.frames) {
          await encodeWebPFile(
            '$testOutputPath/webp/animated_lossy_${frame.frameIndex}.webp',
            frame,
          );
        }
      });

      // Regression: lossless webp with subtractGreen transform decoded as blank
      test('lossless with subtractGreen transform', () async {
        final image = await decodeWebPFile(
          'test/_data/webp/test_animated.webp',
        );
        expect(image, isNotNull);

        var hasVisiblePixel = false;
        for (final pixel in image!) {
          if (pixel.a > 0 && (pixel.r > 0 || pixel.g > 0 || pixel.b > 0)) {
            hasVisiblePixel = true;
            break;
          }
        }
        expect(
          hasVisiblePixel,
          isTrue,
          reason: 'VP8L lossless decoding produced blank image',
        );
      });

      final dir = Directory('test/_data/webp');
      final files = dir.listSync();
      group('getInfo', () {
        for (var f in files.whereType<File>()) {
          if (!f.path.endsWith('.webp')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final List<int> bytes = f.readAsBytesSync();

            final webp = WebPDecoder(bytes);
            final data = webp.info;
            if (data == null) {
              throw ImageException('Unable to parse WebP info: $name.');
            }

            if (_webpTests.containsKey(name)) {
              expect(data.format, equals(_webpTests[name]!['format']));
              expect(data.width, equals(_webpTests[name]!['width']));
              expect(data.height, equals(_webpTests[name]!['height']));
              expect(data.hasAlpha, equals(_webpTests[name]!['hasAlpha']));
              expect(
                data.hasAnimation,
                equals(_webpTests[name]!['hasAnimation']),
              );

              if (data.hasAnimation) {
                expect(
                  webp.numFrames(),
                  equals(_webpTests[name]!['numFrames']),
                );
              }
            }
          });
        }
      });

      group('decode', () {
        test('validate', () {
          var bytes = File('test/_data/webp/2b.webp').readAsBytesSync();
          final image = WebPDecoder().decode(bytes)!;
          final webpBytes = encodeWebP(image);
          File('$testOutputPath/webp/decode.webp')
            ..createSync(recursive: true)
            ..writeAsBytesSync(webpBytes);

          // Validate decoding.
          bytes = File('test/_data/webp/2b.png').readAsBytesSync();
          final debugImage = PngDecoder().decode(bytes)!;

          testImageEquals(image, debugImage);
        });

        for (var f in files) {
          if (f is! File || !f.path.endsWith('.webp')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final List<int> bytes = f.readAsBytesSync();
            final image = WebPDecoder().decode(bytes);
            if (image == null) {
              throw ImageException('Unable to decode WebP Image: $name.');
            }

            final webpBytes = encodeWebP(image);
            File('$testOutputPath/webp/$name.webp')
              ..createSync(recursive: true)
              ..writeAsBytesSync(webpBytes);
          });
        }
      });

      group('decode animation', () {
        test('transparent animation', () {
          const path = 'test/_data/webp/animated_transparency.webp';
          final bytes = File(path).readAsBytesSync();
          final anim = WebPDecoder().decode(bytes)!;

          expect(anim.numFrames, equals(20));

          for (var i = 0; i < anim.numFrames; ++i) {
            final image = anim.getFrame(i);
            File('$testOutputPath/webp/animated_transparency_$i.webp')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodeWebP(image));
          }
          expect(anim.getFrame(2).getPixel(0, 0), equals([0, 0, 0, 0]));
        });
      });

      group('encode', () {
        test('round-trip lossless', () {
          // Decode a lossless webp, encode it, decode again, compare.
          final bytes =
              File('test/_data/webp/1_webp_ll.webp').readAsBytesSync();
          final original = WebPDecoder().decode(bytes)!;

          final encoded = encodeWebP(original);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(original.width));
          expect(decoded.height, equals(original.height));

          // Every visible pixel must come back exactly, and what sits under
          // a fully transparent one is left to the 'exact' test below
          for (var y = 0; y < original.height; y++) {
            for (var x = 0; x < original.width; x++) {
              final op = original.getPixel(x, y);
              final dp = decoded.getPixel(x, y);
              expect(dp.a, equals(op.a), reason: 'A mismatch at ($x,$y)');
              if (op.a == 0) {
                continue;
              }
              expect(dp.r, equals(op.r), reason: 'R mismatch at ($x,$y)');
              expect(dp.g, equals(op.g), reason: 'G mismatch at ($x,$y)');
              expect(dp.b, equals(op.b), reason: 'B mismatch at ($x,$y)');
            }
          }
        });

        test('encode rgb image', () {
          // Create a simple 3-channel image and encode it.
          final image = Image(width: 4, height: 4);
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              image.getPixel(x, y)
                ..r = (x * 60)
                ..g = (y * 60)
                ..b = 128;
            }
          }

          final encoded = encodeWebP(image);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(4));
          expect(decoded.height, equals(4));

          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final dp = decoded.getPixel(x, y);
              expect(dp.r.toInt(), equals(x * 60));
              expect(dp.g.toInt(), equals(y * 60));
              expect(dp.b.toInt(), equals(128));
              expect(dp.a.toInt(), equals(255));
            }
          }
        });

        test('encode rgba image with alpha', () {
          // Create a 4-channel image with varying alpha.
          final image = Image(width: 4, height: 4, numChannels: 4);
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              image.getPixel(x, y)
                ..r = 100
                ..g = 150
                ..b = 200
                ..a = (x + y * 4) * 16; // 0, 16, 32, ...
            }
          }

          final encoded = encodeWebP(image);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(4));
          expect(decoded.height, equals(4));

          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final dp = decoded.getPixel(x, y);
              final alpha = (x + y * 4) * 16;
              expect(dp.a.toInt(), equals(alpha));
              // Colour under a fully transparent pixel is not preserved.
              if (alpha == 0) {
                continue;
              }
              expect(dp.r.toInt(), equals(100));
              expect(dp.g.toInt(), equals(150));
              expect(dp.b.toInt(), equals(200));
            }
          }
        });

        test('encodeWebPFile', () async {
          final image = Image(width: 2, height: 2, numChannels: 4);
          image.getPixel(0, 0)
            ..r = 255
            ..g = 0
            ..b = 0
            ..a = 255;
          image.getPixel(1, 0)
            ..r = 0
            ..g = 255
            ..b = 0
            ..a = 128;
          image.getPixel(0, 1)
            ..r = 0
            ..g = 0
            ..b = 255
            ..a = 64;
          image.getPixel(1, 1)
            ..r = 255
            ..g = 255
            ..b = 0
            ..a = 0;

          final filePath = '$testOutputPath/webp/encode_test.webp';
          File(filePath).parent.createSync(recursive: true);
          await encodeWebPFile(filePath, image);
          expect(File(filePath).existsSync(), isTrue);

          final readBack = File(filePath).readAsBytesSync();
          final decoded = WebPDecoder().decode(readBack);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(2));
          expect(decoded.height, equals(2));
          expect(decoded.getPixel(0, 0).r.toInt(), equals(255));
          expect(decoded.getPixel(1, 0).g.toInt(), equals(255));
          expect(decoded.getPixel(0, 1).b.toInt(), equals(255));
          expect(decoded.getPixel(1, 1).a.toInt(), equals(0));
        });
      });

      // Anything beyond bare pixels needs the extended container: a VP8X chunk
      // announcing what is present, then a chunk for each part.
      group('encode container', () {
        test('preserves EXIF', () {
          final original = WebPDecoder()
              .decode(File('$path/buck_24.webp').readAsBytesSync())!;
          expect(original.exif.imageIfd['Orientation'], IfdValueShort(1));

          final decoded = WebPDecoder().decode(encodeWebP(original))!;
          expect(decoded.exif.imageIfd['Orientation'], IfdValueShort(1),
              reason: 'EXIF should survive a re-encode');
        });

        test('preserves an ICC profile', () {
          final original = PngDecoder()
              .decode(File('test/_data/png/iCCP.png').readAsBytesSync())!;
          expect(original.iccProfile, isNotNull);

          final decoded = WebPDecoder().decode(encodeWebP(original))!;
          expect(decoded.iccProfile, isNotNull,
              reason: 'the profile should survive a re-encode');
          // WebP stores the profile uncompressed while PNG deflates it, so
          // compare what they decompress to rather than the stored bytes.
          expect(decoded.iccProfile!.decompressed(),
              equals(original.iccProfile!.decompressed()));
        });

        test('keeps every frame, its size and its timing', () {
          final original = WebPDecoder().decode(
              File('$path/animated_transparency.webp').readAsBytesSync())!;
          expect(original.numFrames, equals(20));

          final decoded = WebPDecoder().decode(encodeWebP(original))!;
          expect(decoded.numFrames, equals(original.numFrames));
          expect(decoded.width, equals(original.width));
          expect(decoded.height, equals(original.height));
          for (var f = 0; f < original.numFrames; f++) {
            expect(decoded.getFrame(f).frameDuration,
                equals(original.getFrame(f).frameDuration),
                reason: 'duration of frame $f');
          }
        });

        test('codes animation frames without loss', () {
          // Pixel fidelity is checked on frames the decoder hands back
          // untouched. Reading an animation composites every frame onto the
          // canvas, and compositeImage rounds down at low alpha - (1,0,0,15)
          // comes back as (0,0,0,15) - so a semi-transparent frame loses a
          // little on every decode, whatever was written.
          final original = Image(width: 24, height: 16, numChannels: 4)
            ..loopCount = 3;
          for (var f = 0; f < 4; f++) {
            final frame = (f == 0 ? original : original.addFrame())
              ..frameDuration = 40 + f * 10;
            for (var y = 0; y < 16; y++) {
              for (var x = 0; x < 24; x++) {
                frame.getPixel(x, y)
                  ..r = (x * 9 + f * 40) & 0xff
                  ..g = (y * 13) & 0xff
                  ..b = f * 60
                  ..a = 255;
              }
            }
          }

          final decoded = WebPDecoder().decode(encodeWebP(original))!;
          expect(decoded.numFrames, equals(4));
          for (var f = 0; f < 4; f++) {
            final of = original.getFrame(f);
            final df = decoded.getFrame(f);
            expect(df.frameDuration, equals(of.frameDuration));
            for (var y = 0; y < 16; y++) {
              for (var x = 0; x < 24; x++) {
                final e = of.getPixel(x, y);
                final a = df.getPixel(x, y);
                expect([a.r, a.g, a.b, a.a], equals([e.r, e.g, e.b, e.a]),
                    reason: 'frame $f at ($x,$y)');
              }
            }
          }
        });

        test('singleFrame writes just the first frame', () {
          final original = WebPDecoder().decode(
              File('$path/animated_transparency.webp').readAsBytesSync())!;

          final encoded = WebPEncoder().encode(original, singleFrame: true);
          final decoded = WebPDecoder().decode(encoded)!;
          expect(decoded.numFrames, equals(1));
          // With nothing to announce, the simple container is used and the
          // bitstream follows the RIFF header directly.
          expect(String.fromCharCodes(encoded.sublist(12, 16)), equals('VP8L'));
        });

        test('a plain image still uses the simple container', () {
          final image = Image(width: 8, height: 8);
          for (final p in image) {
            p
              ..r = 10
              ..g = 20
              ..b = 30;
          }
          final encoded = encodeWebP(image);
          expect(String.fromCharCodes(encoded.sublist(0, 4)), equals('RIFF'));
          expect(String.fromCharCodes(encoded.sublist(8, 12)), equals('WEBP'));
          expect(String.fromCharCodes(encoded.sublist(12, 16)), equals('VP8L'),
              reason: 'no VP8X when there is nothing extended to announce');
        });

        test('the extended container declares what it carries', () {
          final original = WebPDecoder().decode(
              File('$path/animated_transparency.webp').readAsBytesSync())!;
          final encoded = encodeWebP(original);

          expect(String.fromCharCodes(encoded.sublist(12, 16)), equals('VP8X'));
          final flags = encoded[20];
          expect((flags >> 1) & 1, equals(1), reason: 'animation flag');
          expect(flags & 1, equals(0), reason: 'reserved bit must be clear');
          expect((flags >> 6) & 3, equals(0), reason: 'top bits reserved');

          // The canvas size is stored as two 24 bit values, each minus one.
          int u24(int o) =>
              encoded[o] | (encoded[o + 1] << 8) | (encoded[o + 2] << 16);
          expect(u24(24) + 1, equals(original.width));
          expect(u24(27) + 1, equals(original.height));

          // RIFF size counts everything after it.
          final riffSize = encoded[4] |
              (encoded[5] << 8) |
              (encoded[6] << 16) |
              (encoded[7] << 24);
          expect(riffSize, equals(encoded.length - 8));
        });

        test('reports that it can encode animation', () {
          expect(WebPEncoder().supportsAnimation, isTrue);
        });
      });

      // The color indexing transform replaces each pixel with a palette index,
      // packing several indices into a byte when the palette is small. The
      // sizes below are deliberately not multiples of any packing width, so a
      // wrong sub-sampled stride surfaces as a pixel mismatch.
      group('encode color indexing', () {
        Image buildPaletteImage(int numColors,
            {int width = 61, int height = 37, bool varyAlpha = false}) {
          final image = Image(width: width, height: height, numChannels: 4);
          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              final idx = (y * width + x) % numColors;
              image.getPixel(x, y)
                ..r = (idx * 17) & 0xff
                ..g = (255 - idx * 13) & 0xff
                ..b = (idx * 5 + 40) & 0xff
                ..a = varyAlpha ? (idx * 7) & 0xff : 255;
            }
          }
          return image;
        }

        void expectPixelsEqual(Image expected, Image actual) {
          expect(actual.width, equals(expected.width));
          expect(actual.height, equals(expected.height));
          for (var y = 0; y < expected.height; y++) {
            for (var x = 0; x < expected.width; x++) {
              final e = expected.getPixel(x, y);
              final a = actual.getPixel(x, y);
              expect(a.a, equals(e.a), reason: 'A mismatch at ($x,$y)');
              if (e.a == 0) {
                continue;
              }
              expect(a.r, equals(e.r), reason: 'R mismatch at ($x,$y)');
              expect(a.g, equals(e.g), reason: 'G mismatch at ($x,$y)');
              expect(a.b, equals(e.b), reason: 'B mismatch at ($x,$y)');
            }
          }
        }

        /// The type of the first VP8L transform in [webp], or -1 if the stream
        /// carries none. 0 = predictor, 2 = subtract-green, 3 = color indexing.
        int firstTransform(List<int> webp) {
          // RIFF(4) size(4) 'WEBP'(4) 'VP8L'(4) size(4), then the one-byte
          // signature and the four-byte size/alpha/version header.
          var bitPos = (20 + 5) * 8;
          int readBits(int n) {
            var v = 0;
            for (var i = 0; i < n; i++) {
              v |= ((webp[bitPos >> 3] >> (bitPos & 7)) & 1) << i;
              bitPos++;
            }
            return v;
          }

          return readBits(1) != 0 ? readBits(2) : -1;
        }

        test('round-trip across every packing width', () {
          // 2 and 3 colors pack 8 and 4 indices per byte, 5..16 pack 2, and
          // anything above 16 stores one index per byte.
          for (final numColors in [2, 3, 4, 5, 16, 17, 100, 256]) {
            final original = buildPaletteImage(numColors);
            final encoded = encodeWebP(original);
            expect(firstTransform(encoded), equals(3),
                reason: '$numColors colors should use color indexing');
            final decoded = WebPDecoder().decode(encoded);
            expect(decoded, isNotNull, reason: '$numColors colors failed');
            expectPixelsEqual(original, decoded!);
          }
        });

        test('round-trip preserves alpha', () {
          final original = buildPaletteImage(16, varyAlpha: true);
          final encoded = encodeWebP(original);
          expect(firstTransform(encoded), equals(3));
          expectPixelsEqual(original, WebPDecoder().decode(encoded)!);
        });

        test('round-trip on a single color image', () {
          final original = buildPaletteImage(1, width: 7, height: 3);
          final encoded = encodeWebP(original);
          expect(firstTransform(encoded), equals(3));
          expectPixelsEqual(original, WebPDecoder().decode(encoded)!);
        });

        test('more than 256 colors falls back to the general path', () {
          // buildPaletteImage multiplies the index by odd factors, which wrap
          // modulo 256 and would collapse 257 indices back into 256 colors, so
          // spread the index across two channels instead.
          const width = 61;
          const height = 37;
          final original = Image(width: width, height: height, numChannels: 4);
          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              final idx = (y * width + x) % 257;
              original.getPixel(x, y)
                ..r = idx & 0xff
                ..g = (idx >> 8) & 0xff
                ..b = 200
                ..a = 255;
            }
          }

          final encoded = encodeWebP(original);
          expect(firstTransform(encoded), isNot(equals(3)),
              reason: 'color indexing cannot address more than 256 colors');
          expectPixelsEqual(original, WebPDecoder().decode(encoded)!);
        });

        test('produces a well-formed RIFF/VP8L container', () {
          final encoded = encodeWebP(buildPaletteImage(16));

          String tag(int o) => String.fromCharCodes(encoded.sublist(o, o + 4));
          int u32(int o) =>
              encoded[o] |
              (encoded[o + 1] << 8) |
              (encoded[o + 2] << 16) |
              (encoded[o + 3] << 24);

          expect(tag(0), equals('RIFF'));
          expect(tag(8), equals('WEBP'));
          expect(tag(12), equals('VP8L'));
          // The RIFF size counts everything after it, and the VP8L chunk is
          // padded to an even length.
          expect(u32(4), equals(encoded.length - 8));
          final chunkSize = u32(16);
          expect(20 + chunkSize + (chunkSize.isOdd ? 1 : 0),
              equals(encoded.length));
          expect(encoded[20], equals(0x2f), reason: 'VP8L signature byte');
          // Width and height are stored as 14-bit values, minus one.
          final header = u32(21);
          expect((header & 0x3fff) + 1, equals(61));
          expect(((header >> 14) & 0x3fff) + 1, equals(37));
          expect((header >> 29) & 0x7, equals(0), reason: 'VP8L version');
        });

        test('agrees with the libwebp reference encoding', () {
          // palette_ref.webp was produced by `cwebp -lossless -z 9 -m 6` from
          // the image buildPaletteImage(16) generates. Both encoders are
          // lossless, so the two files must decode to identical pixels.
          final reference = WebPDecoder()
              .decode(File('$path/palette_ref.webp').readAsBytesSync())!;
          expectPixelsEqual(buildPaletteImage(16), reference);

          final ours = WebPDecoder().decode(encodeWebP(buildPaletteImage(16)))!;
          expectPixelsEqual(reference, ours);
        });

        // A lossless encoder has an exact oracle: decoding what it produced has
        // to return the pixels it was given. Sweeping the thresholds where the
        // encoder switches strategy is what turns that oracle into coverage.
        test('round-trip sweep over sizes, color counts and channels', () {
          // A local generator keeps the cases reproducible regardless of what
          // dart:math's Random does.
          var seed = 0x2f6e2b1;
          int next(int n) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            return (seed >> 8) % n;
          }

          const sizes = [
            [1, 1], // single pixel
            [1, 33], // single column
            [33, 1], // single row
            [3, 5],
            [17, 9],
            [61, 37],
            [127, 3], // wide and short, not a multiple of any packing width
          ];
          // Around every packing threshold and the palette cut-off itself.
          const colorCounts = [1, 2, 3, 4, 5, 16, 17, 100, 255, 256, 257];

          for (final size in sizes) {
            final w = size[0];
            final h = size[1];
            for (final numColors in colorCounts) {
              for (final channels in [3, 4]) {
                final reds = List.generate(numColors, (_) => next(256));
                final greens = List.generate(numColors, (_) => next(256));
                final blues = List.generate(numColors, (_) => next(256));
                final alphas = List.generate(numColors, (_) => next(256));

                final original =
                    Image(width: w, height: h, numChannels: channels);
                for (var y = 0; y < h; y++) {
                  for (var x = 0; x < w; x++) {
                    final i = (y * w + x) % numColors;
                    final p = original.getPixel(x, y)
                      ..r = reds[i]
                      ..g = greens[i]
                      ..b = blues[i];
                    if (channels == 4) p.a = alphas[i];
                  }
                }

                final label = '${w}x$h, $numColors colors, $channels channels';
                final decoded = WebPDecoder().decode(encodeWebP(original));
                expect(decoded, isNotNull, reason: 'failed to decode $label');
                expect(decoded!.width, equals(w), reason: label);
                expect(decoded.height, equals(h), reason: label);
                for (var y = 0; y < h; y++) {
                  for (var x = 0; x < w; x++) {
                    final e = original.getPixel(x, y);
                    final a = decoded.getPixel(x, y);
                    if (channels == 4) {
                      expect(a.a, equals(e.a),
                          reason: 'A at ($x,$y) of $label');
                      // Colour under a fully transparent pixel is cleared.
                      if (e.a == 0) {
                        continue;
                      }
                    }
                    expect(a.r, equals(e.r), reason: 'R at ($x,$y) of $label');
                    expect(a.g, equals(e.g), reason: 'G at ($x,$y) of $label');
                    expect(a.b, equals(e.b), reason: 'B at ($x,$y) of $label');
                  }
                }
              }
            }
          }
        });

        test('round-trip on noise, flat fill and fully transparent alpha', () {
          var seed = 0x51f3a7;
          int next(int n) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            return (seed >> 8) % n;
          }

          // Noise defeats LZ77 entirely, a flat fill is nothing but matches,
          // and a zero alpha plane is the case a channel-count check misses.
          final patterns = <String, int Function(int, int, int)>{
            'noise': (x, y, c) => next(256),
            'flat': (x, y, c) => c == 3 ? 255 : 200,
            'transparent': (x, y, c) => c == 3 ? 0 : next(256),
          };

          for (final entry in patterns.entries) {
            final name = entry.key;
            final f = entry.value;
            const w = 41;
            const h = 29;
            final original = Image(width: w, height: h, numChannels: 4);
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                original.getPixel(x, y)
                  ..r = f(x, y, 0)
                  ..g = f(x, y, 1)
                  ..b = f(x, y, 2)
                  ..a = f(x, y, 3);
              }
            }

            final decoded = WebPDecoder().decode(encodeWebP(original));
            expect(decoded, isNotNull, reason: name);
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                final e = original.getPixel(x, y);
                final a = decoded!.getPixel(x, y);
                expect(a.a, equals(e.a), reason: '$name alpha at ($x,$y)');
                // Colour under a fully transparent pixel is cleared, which is
                // most of why the 'transparent' pattern codes so small.
                if (e.a == 0) {
                  continue;
                }
                expect([a.r, a.g, a.b], equals([e.r, e.g, e.b]),
                    reason: '$name at ($x,$y)');
              }
            }
          }
        });

        test('reports alpha_is_used only when alpha is actually present', () {
          // The flag is a hint rather than something the decoder depends on,
          // but libwebp derives it from the pixels and so should this.
          int alphaFlag(List<int> webp) {
            final header = webp[21] |
                (webp[22] << 8) |
                (webp[23] << 16) |
                (webp[24] << 24);
            return (header >> 28) & 1;
          }

          final opaque = Image(width: 8, height: 8, numChannels: 4);
          for (final p in opaque) {
            p
              ..r = 10
              ..g = 20
              ..b = 30
              ..a = 255;
          }
          expect(alphaFlag(encodeWebP(opaque)), equals(0));

          final transparent = Image(width: 8, height: 8, numChannels: 4);
          for (final p in transparent) {
            p
              ..r = 10
              ..g = 20
              ..b = 30
              ..a = 128;
          }
          expect(alphaFlag(encodeWebP(transparent)), equals(1));
        });

        // Meta Huffman gives regions with unlike statistics their own codes,
        // which means the stream now carries an entropy image and several sets
        // of code definitions. Images built of clearly different regions are
        // what exercise that path.
        test('round-trip on an image of regions with unlike statistics', () {
          var seed = 0x1d7c3f;
          int next(int n) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            return (seed >> 8) % n;
          }

          const w = 160;
          const h = 120;
          final original = Image(width: w, height: h, numChannels: 4);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final p = original.getPixel(x, y);
              if (x < w ~/ 3) {
                // Flat: nothing but back-references.
                p
                  ..r = 30
                  ..g = 40
                  ..b = 50
                  ..a = 255;
              } else if (x < 2 * w ~/ 3) {
                // Smooth gradient: small, highly skewed residuals.
                p
                  ..r = (x * 255) ~/ w
                  ..g = (y * 255) ~/ h
                  ..b = 128
                  ..a = 255;
              } else {
                // Noise: flat, wide residual distribution.
                p
                  ..r = next(256)
                  ..g = next(256)
                  ..b = next(256)
                  ..a = 255;
              }
            }
          }

          final decoded = WebPDecoder().decode(encodeWebP(original));
          expect(decoded, isNotNull);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final e = original.getPixel(x, y);
              final a = decoded!.getPixel(x, y);
              expect([a.r, a.g, a.b, a.a], equals([e.r, e.g, e.b, e.a]),
                  reason: 'mismatch at ($x,$y)');
            }
          }
        });

        test('round-trip on regions of unlike statistics with a palette', () {
          // The same split, but few enough colors that the color indexing
          // transform runs first and meta Huffman then works on indices.
          const w = 130;
          const h = 90;
          final original = Image(width: w, height: h, numChannels: 4);
          var seed = 0x77a10b;
          int next(int n) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            return (seed >> 8) % n;
          }

          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final idx = x < w ~/ 2 ? (x + y) % 3 : 3 + next(29);
              original.getPixel(x, y)
                ..r = (idx * 7) & 0xff
                ..g = (idx * 31) & 0xff
                ..b = (idx * 11 + 3) & 0xff
                ..a = 255;
            }
          }

          final decoded = WebPDecoder().decode(encodeWebP(original));
          expect(decoded, isNotNull);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final e = original.getPixel(x, y);
              final a = decoded!.getPixel(x, y);
              expect([a.r, a.g, a.b, a.a], equals([e.r, e.g, e.b, e.a]),
                  reason: 'mismatch at ($x,$y)');
            }
          }
        });

        test('round-trip on strongly cross-correlated channels', () {
          // Red and blue tracking green is what the cross-color transform is
          // for, so this is the shape that exercises it end to end.
          const w = 200;
          const h = 150;
          final original = Image(width: w, height: h);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final base = (x * 3 + y * 5) & 0xff;
              original.getPixel(x, y)
                ..r = (base * 2 + 7) & 0xff
                ..g = base
                ..b = (255 - base) & 0xff;
            }
          }

          final decoded = WebPDecoder().decode(encodeWebP(original));
          expect(decoded, isNotNull);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final e = original.getPixel(x, y);
              final a = decoded!.getPixel(x, y);
              expect([a.r, a.g, a.b], equals([e.r, e.g, e.b]),
                  reason: 'mismatch at ($x,$y)');
            }
          }
        });

        test('codes indices in well under one byte per pixel', () {
          // A 16-color image carries four bits of index per pixel before any
          // entropy coding, so a size near the pixel count would mean the
          // transform had silently stopped being applied.
          final original = buildPaletteImage(16);
          final encoded = encodeWebP(original);
          expect(
              encoded.length, lessThan(original.width * original.height ~/ 2));
        });
      });

      group('encode lossy', () {
        /// A picture with smooth areas, an edge and some texture, which is
        /// enough to exercise every prediction mode.
        Image scene(int w, int h, {bool alpha = false}) {
          final image = Image(width: w, height: h, numChannels: alpha ? 4 : 3);
          var seed = 3;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              seed = (seed * 1103515245 + 12345) & 0x7fffffff;
              final noise = (seed >> 16) & 7;
              final edge = x > w ~/ 2 ? 60 : 0;
              image.getPixel(x, y)
                ..r = (x * 255 ~/ w + edge + noise).clamp(0, 255)
                ..g = (y * 255 ~/ h + noise).clamp(0, 255)
                ..b = (128 - edge + noise).clamp(0, 255);
              if (alpha) {
                // A hard-edged transparent corner, which is where the alpha
                // plane and the colour under it are most likely to go wrong.
                image.getPixel(x, y).a = (x < w ~/ 3 && y < h ~/ 3) ? 0 : 255;
              }
            }
          }
          return image;
        }

        double psnr(Image a, Image b, {bool visibleOnly = false}) {
          var sse = 0.0;
          var count = 0;
          for (var y = 0; y < a.height; y++) {
            for (var x = 0; x < a.width; x++) {
              final p = a.getPixel(x, y);
              final q = b.getPixel(x, y);
              if (visibleOnly && p.a == 0) {
                continue;
              }
              for (final d in [p.r - q.r, p.g - q.g, p.b - q.b]) {
                sse += d * d;
                count++;
              }
            }
          }
          if (sse == 0) {
            return 99;
          }
          return 10 * (log(255 * 255 * count / sse) / ln10);
        }

        test('round-trips close to the source', () {
          final source = scene(96, 64);
          final bytes = encodeWebP(source, lossless: false);
          final decoded = decodeWebP(bytes);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(96));
          expect(decoded.height, equals(64));
          // Lossy, so not pixel for pixel, but nothing like a different image.
          expect(psnr(source, decoded), greaterThan(30));
        });

        test('is a lossy VP8 bitstream, not a lossless one', () {
          final bytes = encodeWebP(scene(64, 64), lossless: false);
          expect(String.fromCharCodes(bytes.sublist(12, 16)), equals('VP8 '));
          expect(bytes.length, lessThan(encodeWebP(scene(64, 64)).length));
        });

        test('quality trades size against fidelity', () {
          final source = scene(128, 96);
          final low = encodeWebP(source, lossless: false, quality: 20);
          final high = encodeWebP(source, lossless: false, quality: 95);
          expect(low.length, lessThan(high.length));
          expect(psnr(source, decodeWebP(low)!),
              lessThan(psnr(source, decodeWebP(high)!)));
        });

        test('every effort level codes a valid stream', () {
          // The trellis only runs at the two highest levels, and the fast
          // levels take a different path through the mode search entirely, so
          // nothing below exercises them.
          final source = scene(64, 48);
          for (var method = 0; method <= 6; method++) {
            final bytes = encodeWebP(source, lossless: false, method: method);
            final decoded = decodeWebP(bytes);
            expect(decoded, isNotNull, reason: 'method $method');
            expect(psnr(source, decoded!), greaterThan(30),
                reason: 'method $method');
          }
        });

        test('diffuses the chroma DC error below quality 98', () {
          // Banding is what this is for: on a smooth ramp every block rounds
          // its chroma DC the same way and the result is a staircase, so the
          // leftover is spread into the neighbours instead. It is off at the
          // top of the quality range, where there is nothing to spread.
          Image ramp(int w, int h) {
            final image = Image(width: w, height: h);
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                image.getPixel(x, y)
                  ..r = 128 + x * 32 ~/ w
                  ..g = 128
                  ..b = 128 - x * 16 ~/ w;
              }
            }
            return image;
          }

          final yuv = importYuv(ramp(16, 16));
          expect(VP8EncState(VP8Config(quality: 98), yuv).topDerr, isNotNull,
              reason: 'diffusion is on at the threshold');
          expect(VP8EncState(VP8Config(quality: 99), yuv).topDerr, isNull,
              reason: 'and off above it');

          final source = ramp(128, 64);
          for (final quality in [10, 50, 98, 99]) {
            final bytes = encodeWebP(source, lossless: false, quality: quality);
            final decoded = decodeWebP(bytes);
            expect(decoded, isNotNull, reason: 'quality $quality');
            expect(psnr(source, decoded!), greaterThan(30),
                reason: 'quality $quality');
          }

          // The error travels between macroblocks, so it has to survive a
          // picture that is not a whole number of them in either direction.
          expect(
              decodeWebP(encodeWebP(ramp(37, 21), lossless: false)), isNotNull);
        });

        test('alphaQuality reduces the alpha plane, and 100 keeps it', () {
          // A radial falloff, as in a real soft mask: a linear ramp is what
          // the horizontal filter predicts perfectly, so its alpha plane is
          // already almost free and there is nothing for this to save.
          const size = 128;
          final source = Image(width: size, height: size, numChannels: 4);
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              final dx = (x - size / 2) / (size / 2);
              final dy = (y - size / 2) / (size / 2);
              final r = sqrt(dx * dx + dy * dy);
              source.getPixel(x, y)
                ..r = 40 + x
                ..g = 90
                ..b = 200 - y
                ..a = (255 * (1 - r).clamp(0.0, 1.0)).round();
            }
          }
          int levels(Image image) {
            final seen = <int>{};
            for (final p in image) {
              seen.add(p.a.toInt());
            }
            return seen.length;
          }

          // The default keeps every level, whatever the lossy quality is.
          final exact = decodeWebP(encodeWebP(source,
              lossless: false, quality: 40, alphaQuality: 100))!;
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              expect(exact.getPixel(x, y).a, equals(source.getPixel(x, y).a),
                  reason: 'alpha at $x,$y');
            }
          }

          // Lower settings quantize it, to libwebp's mapping: quality 70 is
          // sixteen levels, and below that fewer.
          final reduced = decodeWebP(
              encodeWebP(source, lossless: false, alphaQuality: 70))!;
          expect(levels(reduced), equals(16));
          expect(
              levels(decodeWebP(
                  encodeWebP(source, lossless: false, alphaQuality: 20))!),
              lessThan(16));

          // Which is the point: fewer levels, smaller plane, monotonically.
          final atFull =
              encodeWebP(source, lossless: false, alphaQuality: 100).length;
          final atSeventy =
              encodeWebP(source, lossless: false, alphaQuality: 70).length;
          final atTwenty =
              encodeWebP(source, lossless: false, alphaQuality: 20).length;
          expect(atSeventy, lessThan(atFull));
          expect(atTwenty, lessThan(atSeventy));
        });

        test('the arithmetic the encoder relies on is web-safe', () {
          // A Dart int is a double on the web, `<<` is a 32-bit shift there,
          // and `>>` returns its result *unsigned*, so `-5 >> 1` is 4294967293
          // rather than -3. The transforms shift signed intermediates on every
          // block, and getting this wrong once cost 26 dB without failing a
          // single test: the VM was fine and nothing here ran the web build.
          //
          // These check the two invariants the encoder depends on. They pass
          // trivially on the VM; their value is that `dart test -p chrome`, or
          // any web CI, runs them too.
          expect(maxCost, greaterThan(1 << 30),
              reason: 'the score ceiling must not collapse to a small value');
          expect(maxCost, equals(1125899906842624));
          for (final v in [-5, -1, -7, -8, -9, -20091000, -1812, 5, 0]) {
            for (final n in [1, 2, 3, 9, 16]) {
              expect(sar(v, n), equals((v / (1 << n)).floor()),
                  reason: 'sar($v, $n) must be an arithmetic shift');
            }
          }
        });

        test('keeps the alpha channel exactly', () {
          final source = scene(80, 48, alpha: true);
          final bytes = encodeWebP(source, lossless: false);
          // Transparency cannot ride in the VP8 bitstream, so it needs the
          // extended container and its own chunk.
          expect(String.fromCharCodes(bytes.sublist(12, 16)), equals('VP8X'));
          final decoded = decodeWebP(bytes)!;
          for (var y = 0; y < source.height; y++) {
            for (var x = 0; x < source.width; x++) {
              expect(decoded.getPixel(x, y).a, equals(source.getPixel(x, y).a),
                  reason: 'alpha at ($x,$y)');
            }
          }
          expect(psnr(source, decoded, visibleOnly: true), greaterThan(30));
        });

        test('handles sizes that are not whole macroblocks', () {
          for (final size in [
            [1, 1],
            [1, 17],
            [17, 1],
            [15, 15],
            [17, 33],
            [64, 3]
          ]) {
            final source = scene(size[0], size[1]);
            final decoded = decodeWebP(encodeWebP(source, lossless: false));
            expect(decoded, isNotNull, reason: '${size[0]}x${size[1]}');
            expect(decoded!.width, equals(size[0]));
            expect(decoded.height, equals(size[1]));
          }
        });

        test('refuses an image the format cannot describe', () {
          expect(
              () => encodeWebP(Image(width: maxDimension + 1, height: 2),
                  lossless: false),
              throwsA(isA<ImageException>()));
        });
      });

      group('dimension limit', () {
        test('refuses an image the format cannot describe', () {
          // The VP8L header has fourteen bits per dimension. Overflowing it
          // used to produce a stream that decoded to nothing at all.
          expect(() => encodeWebP(Image(width: maxDimension + 1, height: 2)),
              throwsA(isA<ImageException>()));
          expect(() => encodeWebP(Image(width: 2, height: maxDimension + 1)),
              throwsA(isA<ImageException>()));

          // The largest allowed image still round-trips.
          final widest = Image(width: maxDimension, height: 2);
          final decoded = decodeWebP(encodeWebP(widest));
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(maxDimension));
        });

        test('refuses an empty image', () {
          // The other end of the same field. `copyResize` reaches it on any
          // picture thin enough that the scaled side rounds to nothing.
          for (final size in const [
            [0, 4],
            [4, 0],
            [0, 0],
          ]) {
            for (final lossless in const [true, false]) {
              expect(
                  () => encodeWebP(Image(width: size[0], height: size[1]),
                      lossless: lossless),
                  throwsA(isA<ImageException>()),
                  reason: '${size[0]}x${size[1]} lossless=$lossless');
            }
          }
        });
      });

      group('token stream', () {
        // The greedy cover is priced, then overwritten in place by the optimal
        // one, so the two share their arrays. That only holds because the
        // optimal parse writes every position the token stream is later read
        // back from. Break it and the encoder still emits a valid file, just a
        // worse one built partly from the discarded parse, which no round-trip
        // can see.
        test('the optimal parse writes every position that is read back', () {
          for (final size in const [
            [1, 1],
            [3, 3],
            [16, 1],
            [37, 23],
            [64, 48],
          ]) {
            final w = size[0];
            final h = size[1];
            final n = w * h;
            final r = Uint8List(n);
            final g = Uint8List(n);
            final b = Uint8List(n);
            final a = Uint8List(n)..fillRange(0, n, 255);
            // Runs and noise together, so the parse produces both long
            // back-references and stretches of literals.
            var s = 7;
            for (var i = 0; i < n; i++) {
              s = (s * 16807) % 2147483647;
              final flat = (i ~/ w) % 3 == 0;
              r[i] = flat ? 60 : (s >> 8) & 0xff;
              g[i] = flat ? 120 : (s >> 12) & 0xff;
              b[i] = flat ? 200 : (s >> 16) & 0xff;
            }

            final matches = computeMatches(r, g, b, a, n, w);
            final allLiterals = VP8LCover(n)..cover.fillRange(0, n, 1);
            final costs = VP8LCostModel.fromCover(allLiterals, r, g, b, a, w);

            // Poison, so that reading a position the parse did not write is a
            // detectable value rather than a plausible one.
            const poison = 0x0badf00d;
            final parse = VP8LCover(n)
              ..cover.fillRange(0, n, poison)
              ..distance.fillRange(0, n, poison);
            optimalCover(matches, costs, r, g, b, a, w, parse);
            final cover = parse.cover;
            final coverDistance = parse.distance;

            // Walk the cover exactly as refsFromCover does.
            var i = 0;
            var tokens = 0;
            while (i < n) {
              expect(cover[i], isNot(equals(poison)),
                  reason: '${w}x$h: token at $i was left by the greedy parse');
              final len = cover[i];
              expect(len, greaterThanOrEqualTo(1),
                  reason: '${w}x$h: token at $i has length $len');
              if (len > 1) {
                expect(coverDistance[i], isNot(equals(poison)),
                    reason: '${w}x$h: distance at $i was never written');
              }
              i += len > 1 ? len : 1;
              tokens++;
            }
            expect(i, equals(n), reason: '${w}x$h: the walk overran the image');

            // And the same walk is what builds the arrays, so their lengths
            // have to agree with it.
            final refs = refsFromCover(parse);
            expect(refs.isLiteral.length, equals(tokens), reason: '${w}x$h');
            expect(
                refs.literalIndex.length + refs.length.length, equals(tokens),
                reason: '${w}x$h');
            expect(refs.distance.length, equals(refs.length.length),
                reason: '${w}x$h');
            expect(refs.position.length, equals(tokens), reason: '${w}x$h');
          }
        });
      });

      group('transparent pixels', () {
        Image withHiddenColour() {
          final image = Image(width: 40, height: 30, numChannels: 4);
          var seed = 7;
          for (var y = 0; y < 30; y++) {
            for (var x = 0; x < 40; x++) {
              seed = (seed * 1103515245 + 12345) & 0x7fffffff;
              image.getPixel(x, y)
                ..r = (seed >> 8) & 0xff
                ..g = (seed >> 12) & 0xff
                ..b = (seed >> 16) & 0xff
                // A transparent left half against an opaque right half.
                ..a = x < 20 ? 0 : 255;
            }
          }
          return image;
        }

        test('are kept by default and cleared only when asked', () {
          final original = withHiddenColour();

          final strictImage = decodeWebP(encodeWebP(original))!;
          final looseImage = decodeWebP(encodeWebP(original, exact: false))!;

          var cleared = 0;
          for (var y = 0; y < original.height; y++) {
            for (var x = 0; x < original.width; x++) {
              final want = original.getPixel(x, y);
              final loose = looseImage.getPixel(x, y);
              final strict = strictImage.getPixel(x, y);

              // Alpha survives either way, and so does every visible pixel.
              expect(loose.a, equals(want.a), reason: 'alpha at $x,$y');
              expect(strict.a, equals(want.a), reason: 'alpha at $x,$y');
              if (want.a != 0) {
                expect([loose.r, loose.g, loose.b],
                    equals([want.r, want.g, want.b]),
                    reason: 'visible pixel changed at $x,$y');
              }

              expect([strict.r, strict.g, strict.b],
                  equals([want.r, want.g, want.b]),
                  reason: 'the default should have preserved $x,$y');
              if (want.a == 0 &&
                  loose.r == 0 &&
                  loose.g == 0 &&
                  loose.b == 0 &&
                  want.r != 0) {
                cleared++;
              }
            }
          }
          expect(cleared, greaterThan(0),
              reason: 'nothing was cleared, so exact: false did nothing');

          // The whole point of clearing is that it codes smaller.
          expect(encodeWebP(original, exact: false).length,
              lessThan(encodeWebP(original).length));
        });
      });

      group('transform analysis', () {
        // Building an image whose pixels favour a particular transform set.
        Image synth(int w, int h, int Function(int x, int y) argb) {
          final im = Image(width: w, height: h, numChannels: 4);
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final v = argb(x, y);
              im.getPixel(x, y)
                ..a = (v >> 24) & 0xff
                ..r = (v >> 16) & 0xff
                ..g = (v >> 8) & 0xff
                ..b = v & 0xff;
            }
          }
          return im;
        }

        test('every transform set it picks still round-trips', () {
          final rnd = Random(4711);
          final cases = <String, Image>{
            // Smooth in space and correlated across channels.
            'gradient': synth(70, 50,
                (x, y) => 0xff000000 | ((x + y) * 0x010101) & 0x00ffffff),
            // Grey: red and blue vanish under subtract-green, so cross-color
            // has nothing left to do.
            'grey': synth(70, 50, (x, y) {
              final v = (x * 3 + y * 5) & 0xff;
              return 0xff000000 | (v << 16) | (v << 8) | v;
            }),
            // Noise defeats spatial prediction entirely.
            'noise':
                synth(70, 50, (x, y) => 0xff000000 | rnd.nextInt(0x01000000)),
            // Channels that move together but not across space.
            'channel-locked': synth(70, 50, (x, y) {
              final v = rnd.nextInt(200);
              return 0xff000000 | (v << 16) | ((v + 20) << 8) | (v + 40);
            }),
          };

          final seen = <String>{};
          for (final entry in cases.entries) {
            final source = entry.value;
            final argb = Uint32List(source.width * source.height);
            var i = 0;
            for (var y = 0; y < source.height; y++) {
              for (var x = 0; x < source.width; x++) {
                final p = source.getPixel(x, y);
                argb[i++] = (p.a.toInt() << 24) |
                    (p.r.toInt() << 16) |
                    (p.g.toInt() << 8) |
                    p.b.toInt();
              }
            }
            final choice = analyzeEntropy(argb, source.width, source.height, 4);
            seen.add('${choice.useSubtractGreen}${choice.usePredictor}'
                '${choice.useCrossColor}');

            final decoded = decodeWebP(encodeWebP(source));
            expect(decoded, isNotNull, reason: entry.key);
            for (var y = 0; y < source.height; y++) {
              for (var x = 0; x < source.width; x++) {
                final want = source.getPixel(x, y);
                final got = decoded!.getPixel(x, y);
                expect([
                  got.r,
                  got.g,
                  got.b,
                  got.a
                ], [
                  want.r,
                  want.g,
                  want.b,
                  want.a
                ], reason: '${entry.key} at $x,$y');
              }
            }
          }

          // The transforms are optional now, and a change that quietly made
          // one of them unconditional again would still round-trip. What would
          // give it away is the choice collapsing onto a single set.
          expect(seen.length, greaterThanOrEqualTo(3),
              reason: 'transform selection collapsed to $seen');
        });
      });

      group('predictors', () {
        test('the fused search agrees with the plain formulas', () {
          // The mode search cannot afford to ask for one prediction at a time,
          // so predictAll states the same fourteen formulas a second time with
          // the shared averages factored out. Nothing in the encoder would
          // notice if the two drifted apart: the stream would stay decodable
          // and merely code worse. This is what notices.
          final rnd = Random(20260903);
          final out = Uint32List(numPredictors);
          for (var trial = 0; trial < 2000; trial++) {
            // Cover the clamping edges of predictors 12 and 13, which only
            // trigger when neighbours sit near 0 or 255.
            final int Function() pick = switch (trial % 3) {
              0 => () => rnd.nextInt(0x100000000),
              1 => () => rnd.nextBool() ? 0x00000000 : 0xffffffff,
              _ => () => (rnd.nextInt(4) == 0 ? 0xff : 0) * 0x01010101,
            };
            final left = pick();
            final top = pick();
            final topLeft = pick();
            final topRight = pick();
            predictAll(left, top, topLeft, topRight, out);
            for (var m = 0; m < numPredictors; m++) {
              expect(out[m], predict(m, left, top, topLeft, topRight),
                  reason: 'predictor $m on '
                      '${left.toRadixString(16)} ${top.toRadixString(16)} '
                      '${topLeft.toRadixString(16)} '
                      '${topRight.toRadixString(16)}');
            }
          }
        });
      });
    });

    group('container', () {
      test('the animation background color is stored blue, green, red, alpha',
          () {
        // Packed the way the channels are named, the bytes land reversed and
        // opaque red reads as transparent cyan in every other reader.
        final anim = _flat(32, 32, 10, 20, 30)
          ..backgroundColor = ColorRgba8(255, 0, 0, 255);
        anim.addFrame(_flat(32, 32, 30, 20, 10)).frameDuration = 100;

        final payload = _chunk(encodeWebP(anim), 'ANIM')!;
        expect(payload.sublist(0, 4), equals([0, 0, 255, 255]),
            reason: 'blue, green, red, alpha');

        final decoder = WebPDecoder(encodeWebP(anim));
        final back = decoder.info!.backgroundColor!;
        expect([back.r, back.g, back.b, back.a], equals([255, 0, 0, 255]));
      });

      test(
          'the alpha flag says what the file carries, not how many channels '
          'the image had', () {
        // Opaque throughout, so no alpha is written and claiming it leaves a
        // reader looking for a transparency the file does not have.
        final opaque = _flat(64, 64, 90, 140, 200, channels: 4);
        opaque.exif.imageIfd['Make'] = 'test';
        expect((_chunk(encodeWebP(opaque), 'VP8X')![0] >> 4) & 1, equals(0),
            reason: 'opaque four channel image with metadata');

        final transparent =
            _flat(64, 64, 90, 140, 200, channels: 4, alpha: 128);
        transparent.exif.imageIfd['Make'] = 'test';
        expect(
            (_chunk(encodeWebP(transparent), 'VP8X')![0] >> 4) & 1, equals(1),
            reason: 'the same image with a transparency');
      });

      test('the animation background color is scaled to eight bits', () {
        // The chunk holds one byte a channel, so a sixteen bit source
        // written raw spills its high byte into the channel packed above
        final anim = Image(
            width: 16, height: 16, numChannels: 3, format: Format.uint16)
          ..backgroundColor = ColorUint16.rgba(0x1234, 0x5678, 0x9abc, 0xffff);
        anim.addFrame().frameDuration = 100;

        final payload = _chunk(encodeWebP(anim), 'ANIM')!;
        expect(payload.sublist(0, 4), equals([0x9a, 0x56, 0x12, 0xff]),
            reason: 'blue, green, red, alpha, each scaled from 16 bits');
      });

      test('a loop count past its field is clamped, not wrapped', () {
        // Sixteen bits, so wrapping turns 70000 loops into 4464
        int written(int loopCount) {
          final anim = _flat(16, 16, 10, 20, 30)..loopCount = loopCount;
          anim.addFrame(_flat(16, 16, 30, 20, 10)).frameDuration = 100;
          final payload = _chunk(encodeWebP(anim), 'ANIM')!;
          return payload[4] | (payload[5] << 8);
        }

        expect(written(70000), equals(0xffff), reason: 'past the field');
        expect(written(-1), equals(0), reason: 'below the field');
        expect(written(300), equals(300), reason: 'inside the field');
      });

      test('a frame duration past its field is clamped, not wrapped', () {
        // Twenty four bits, so wrapping turns a negative duration into a pause
        // of over four hours that webpinfo reports as sound
        int written(int duration) {
          final anim = _flat(16, 16, 10, 20, 30)..frameDuration = duration;
          anim.addFrame(_flat(16, 16, 30, 20, 10)).frameDuration = 100;
          final payload = _chunk(encodeWebP(anim), 'ANMF')!;
          return payload[12] | (payload[13] << 8) | (payload[14] << 16);
        }

        expect(written(0x1000064), equals(0xffffff), reason: 'past the field');
        expect(written(-5), equals(0), reason: 'below the field');
        expect(written(100), equals(100), reason: 'inside the field');
      });

      test('refuses a frame larger than the canvas', () {
        // libwebp's demuxer fails the whole file when a frame overruns the
        // canvas, so the alternative is an animation that reads nowhere
        final anim = _flat(32, 32, 10, 20, 30);
        anim.addFrame(_flat(64, 64, 30, 20, 10)).frameDuration = 100;
        expect(() => encodeWebP(anim), throwsA(isA<ImageException>()));

        final wide = _flat(32, 32, 10, 20, 30);
        wide.addFrame(_flat(64, 32, 30, 20, 10)).frameDuration = 100;
        expect(() => encodeWebP(wide), throwsA(isA<ImageException>()),
            reason: 'one side over is enough');

        final small = _flat(32, 32, 10, 20, 30);
        small.addFrame(_flat(16, 16, 30, 20, 10)).frameDuration = 100;
        expect(decodeWebP(encodeWebP(small)), isNotNull);
      });
    });

    group('animation round trip', () {
      test('a semi transparent frame comes back at its own colour', () {
        // Frames are whole pictures drawn on a canvas the previous frame
        // cleared, and blending one against an empty canvas leaves its colour
        // multiplied by its own alpha
        final frame = _flat(16, 16, 200, 100, 50, channels: 4, alpha: 128);
        frame
            .addFrame(_flat(16, 16, 200, 100, 50, channels: 4, alpha: 128))
            .frameDuration = 100;
        frame.frameDuration = 100;

        final back = decodeWebP(encodeWebP(frame))!;
        expect(back.frames.length, equals(2));
        for (var i = 0; i < back.frames.length; i++) {
          final p = back.frames[i].getPixel(8, 8);
          expect([p.r, p.g, p.b, p.a], equals([200, 100, 50, 128]),
              reason: 'frame $i');
        }
      });

      test('the dispose flag clears after its own frame, not before it', () {
        // The flag says what to do once its own frame has been shown, so
        // reading it as an instruction for that frame wipes what the previous
        // one left behind
        final red = _flat(32, 32, 255, 0, 0, channels: 4);
        final blue = _flat(16, 16, 0, 0, 255, channels: 4);

        // Only the second frame asks for a dispose, so the red one has to
        // survive under the blue
        final bytes = _animation([red, blue], const [false, true]);
        final back = decodeWebP(bytes)!;

        expect(back.frames.length, equals(2));
        final covered = back.frames[1].getPixel(4, 4);
        expect([covered.r, covered.g, covered.b], equals([0, 0, 255]),
            reason: 'the blue frame itself');
        final kept = back.frames[1].getPixel(24, 24);
        expect([kept.r, kept.g, kept.b, kept.a], equals([255, 0, 0, 255]),
            reason: 'the red frame was not disposed, so it shows through');
      });

      test('the decoded image carries the fields the file holds', () {
        // The decoder parses loop count, background, ICC and EXIF into
        // WebPInfo, and leaving them there drops them from a decode and
        // encode again
        final anim = _flat(16, 16, 10, 20, 30)
          ..loopCount = 7
          ..backgroundColor = ColorRgba8(255, 0, 0, 255)
          ..frameDuration = 100
          ..iccProfile = IccProfile('p', IccProfileCompression.none,
              Uint8List.fromList(List<int>.generate(64, (i) => i)));
        anim.exif.imageIfd['Make'] = 'roundtrip';
        anim.addFrame(_flat(16, 16, 30, 20, 10)).frameDuration = 100;

        final back = decodeWebP(encodeWebP(anim))!;

        expect(back.loopCount, equals(7));
        final bg = back.backgroundColor;
        expect(bg, isNotNull, reason: 'background colour');
        expect([bg!.r, bg.g, bg.b, bg.a], equals([255, 0, 0, 255]));
        expect(back.iccProfile?.data.length, equals(64));
        expect(back.exif.imageIfd['Make']?.toString(), equals('roundtrip'));
      });

      test('a still image carries its metadata too', () {
        final still = _flat(16, 16, 10, 20, 30)
          ..iccProfile = IccProfile('p', IccProfileCompression.none,
              Uint8List.fromList(List<int>.generate(64, (i) => i)));
        still.exif.imageIfd['Make'] = 'roundtrip';

        final back = decodeWebP(encodeWebP(still))!;
        expect(back.iccProfile?.data.length, equals(64));
        expect(back.exif.imageIfd['Make']?.toString(), equals('roundtrip'));
      });
    });

    group('metadata', () {
      test('encoding leaves the profile on the image it was given alone', () {
        // The profile has to be inflated for the chunk, and inflating in
        // place leaves the caller a profile whose bytes no longer match its
        // own compression field
        final image = _flat(8, 8, 1, 2, 3)
          ..iccProfile = IccProfile('p', IccProfileCompression.none,
              Uint8List.fromList(List<int>.generate(512, (i) => i & 0xff)));
        final deflated = image.iccProfile!.compressed();
        final length = deflated.length;

        final written = _chunk(encodeWebP(image), 'ICCP')!;

        expect(image.iccProfile!.compression,
            equals(IccProfileCompression.deflate),
            reason: 'the profile on the image was decompressed in place');
        expect(image.iccProfile!.data.length, equals(length),
            reason: 'the bytes on the image were replaced');
        expect(written.length, equals(512),
            reason: 'the chunk carries the inflated profile');
      });
    });

    group('alpha chunk', () {
      test('a plane reduced to fewer levels says so in its header', () {
        // Quantizing leaves steps in a gradient, and the flag is what tells a
        // decoder to smooth them.
        final soft = Image(width: 96, height: 96, numChannels: 4);
        for (var y = 0; y < 96; y++) {
          for (var x = 0; x < 96; x++) {
            soft.getPixel(x, y)
              ..r = 200
              ..g = 120
              ..b = 60
              ..a = (x * 255 / 95).round();
          }
        }

        int preprocessing(int alphaQuality) {
          final webp = encodeWebP(soft,
              lossless: false, quality: 90, alphaQuality: alphaQuality);
          return (_chunk(webp, 'ALPH')![0] >> 4) & 3;
        }

        expect(preprocessing(20), equals(1), reason: 'levels were reduced');
        expect(preprocessing(100), equals(0), reason: 'the plane is exact');
      });

      test('no filtering is weighed even when the estimate prefers a filter',
          () {
        // Filtering this plane costs a quarter more than leaving it alone,
        // and the fast search chooses between the two, so it can never lose to
        // asking for no filtering.
        final image =
            decodePng(File('test/_data/png/test.png').readAsBytesSync())!;
        final plane = Uint8List(image.width * image.height);
        var i = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            plane[i++] = image.getPixel(x, y).a.toInt();
          }
        }

        final fast = encodeAlphaChunk(plane, image.width, image.height,
            filtering: alphaFilterFast);
        final none = encodeAlphaChunk(plane, image.width, image.height,
            filtering: alphaFilterNone);
        expect(fast.length, lessThanOrEqualTo(none.length));
      });
    });

    group('bit writer', () {
      test('the bytes it hands back are exactly the bytes written', () {
        // The buffer grows by doubling, so the result is cut to the length
        // written.
        for (final count in const [1, 7, 4095, 4096, 4097, 9000]) {
          final w = VP8LBitWriter();
          for (var i = 0; i < count; i++) {
            w.writeBits(i & 0xff, 8);
          }
          w.flush();
          final bytes = w.getBytes();
          expect(bytes.length, equals(count), reason: '$count bytes');
          for (var i = 0; i < count; i++) {
            expect(bytes[i], equals(i & 0xff), reason: 'byte $i of $count');
          }
        }
      });

      test('bits shorter than a byte pack low end first', () {
        final w = VP8LBitWriter()
          ..writeBits(1, 1)
          ..writeBits(0, 1)
          ..writeBits(3, 2)
          ..writeBits(0, 4)
          ..flush();
        expect(w.getBytes(), equals([0x0d]));
      });
    });

    group('source formats', () {
      test('a two channel image keeps its transparency', () {
        // Two channels is luminance and alpha. Reading alpha only from four
        // channel images writes the picture opaque.
        final gray = Image(width: 64, height: 64, numChannels: 2);
        for (var y = 0; y < 64; y++) {
          for (var x = 0; x < 64; x++) {
            gray.getPixel(x, y)
              ..r = x * 4
              ..a = y * 4;
          }
        }

        for (final lossless in const [true, false]) {
          final back =
              decodeWebP(encodeWebP(gray, exact: true, lossless: lossless))!;
          for (var y = 0; y < 64; y++) {
            for (var x = 0; x < 64; x++) {
              expect(back.getPixel(x, y).a, equals(gray.getPixel(x, y).a),
                  reason: 'alpha at $x,$y, lossless $lossless');
            }
          }
        }
      });

      test('a one channel image is grey, not red', () {
        // Pixel.g and Pixel.b answer zero for a one channel image, so
        // reading them writes the picture in red, while the lossy path
        // converts to YUV and gets it right
        final gray = Image(width: 32, height: 32, numChannels: 1);
        for (var y = 0; y < 32; y++) {
          for (var x = 0; x < 32; x++) {
            gray.getPixel(x, y).r = x * 8;
          }
        }

        final lossless = decodeWebP(encodeWebP(gray))!;
        for (var y = 0; y < 32; y++) {
          for (var x = 0; x < 32; x++) {
            final want = gray.getPixel(x, y).r;
            final p = lossless.getPixel(x, y);
            expect([p.r, p.g, p.b], equals([want, want, want]),
                reason: 'lossless at $x,$y');
          }
        }

        final lossy =
            decodeWebP(encodeWebP(gray, lossless: false, quality: 95))!;
        final p = lossy.getPixel(20, 5);
        expect(p.g, closeTo(p.r, 2), reason: 'lossy pixel is not grey');
        expect(p.b, closeTo(p.r, 2), reason: 'lossy pixel is not grey');
      });

      test('a sixteen bit image is scaled down, not clipped', () {
        // Clamping instead of scaling turns every value above 255 white,
        // which is most of a 16 bit image.
        final deep =
            Image(width: 64, height: 64, numChannels: 4, format: Format.uint16);
        for (var y = 0; y < 64; y++) {
          for (var x = 0; x < 64; x++) {
            deep.getPixel(x, y)
              ..r = x * 1024
              ..g = y * 1024
              ..b = 32768
              ..a = 65535 - y * 512;
          }
        }

        final back = decodeWebP(encodeWebP(deep, exact: true))!;
        for (var y = 0; y < 64; y++) {
          for (var x = 0; x < 64; x++) {
            final p = deep.getPixel(x, y);
            final q = back.getPixel(x, y);
            for (final (name, want, got) in [
              ('red', p.r, q.r),
              ('green', p.g, q.g),
              ('blue', p.b, q.b),
              ('alpha', p.a, q.a),
            ]) {
              expect(got, closeTo(want * 255 / 65535, 1),
                  reason: '$name at $x,$y');
            }
          }
        }
      });
    });

    group('huffman', () {
      test('a code with one symbol costs no bits', () {
        // A length of one puts a spare bit before every token of the group
        // and the rest of the stream decodes as garbage. Only symbols above
        // 255 reach it: the simple format takes the rest.
        for (final symbol in const [0, 1, 7, 255, 268, 279]) {
          final lengths = List<int>.filled(280, 0)..[symbol] = 1;
          writeHuffmanCode(VP8LBitWriter(), 280, lengths);
          expect(lengths[symbol], equals(0), reason: 'symbol $symbol');
        }
      });
    });
  });
}

const _webpTests = {
  '1.webp': {
    'format': WebPFormat.lossy,
    'width': 550,
    'height': 368,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '1_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '1_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '2.webp': {
    'format': WebPFormat.lossy,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '2b.webp': {
    'format': WebPFormat.lossy,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '2_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '2_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '3.webp': {
    'format': WebPFormat.lossy,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '3_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '3_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '4.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '4_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '4_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '5.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '5_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '5_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  'BladeRunner.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75,
  },
  'BladeRunner_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75,
  },
  'red.webp': {
    'format': WebPFormat.lossy,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  'SteamEngine.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31,
  },
  'SteamEngine_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31,
  },
};

/// A single colour image.
Image _flat(int w, int h, int r, int g, int b,
    {int channels = 3, int alpha = 255}) {
  final im = Image(width: w, height: h, numChannels: channels);
  for (final p in im) {
    p
      ..r = r
      ..g = g
      ..b = b;
    if (channels == 4) {
      p.a = alpha;
    }
  }
  return im;
}

/// An animation built chunk by chunk, since [WebPEncoder] writes the same
/// dispose flag on every frame
Uint8List _animation(List<Image> frames, List<bool> clearAfter) {
  final chunks = <WebPChunk>[
    WebPChunk(
        'VP8X',
        vp8xChunkData(
            vp8xFlags(
                hasIcc: false,
                hasAlpha: true,
                hasExif: false,
                hasXmp: false,
                hasAnimation: true),
            frames.first.width,
            frames.first.height)),
    WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
  ];
  for (var i = 0; i < frames.length; i++) {
    chunks.add(WebPChunk(
        'ANMF',
        anmfChunkData(
            x: 0,
            y: 0,
            width: frames[i].width,
            height: frames[i].height,
            duration: 100,
            clearToBackground: clearAfter[i],
            blend: false,
            frame: [
              WebPChunk('VP8L', VP8LEncoder(exact: true).encodeVP8L(frames[i])),
            ])));
  }
  return buildRiff(chunks);
}

/// The payload of the first [id] chunk of a RIFF file, or null.
Uint8List? _chunk(Uint8List bytes, String id) {
  var p = 12;
  while (p + 8 <= bytes.length) {
    final here = String.fromCharCodes(bytes.sublist(p, p + 4));
    final size = bytes.buffer.asByteData().getUint32(p + 4, Endian.little);
    if (here == id) {
      return Uint8List.sublistView(bytes, p + 8, p + 8 + size);
    }
    p += 8 + size + (size & 1);
  }
  return null;
}
