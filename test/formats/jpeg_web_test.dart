// JPEG behavior that has to hold on the web as well as on the VM.
//
// Kept apart from `jpeg_test.dart` because that one reads files, and so cannot
// run in a browser. Everything here is synthetic, so this file runs under
//
//     dart test -p chrome test/formats/jpeg_web_test.dart
//     dart test -p chrome -c dart2wasm test/formats/jpeg_web_test.dart
//
// as well as in the normal suite. The web build uses its own IDCT
// (`_jpeg_quantize_html.dart`) because dart2js shifts are 32-bit.

import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

Image _gradient(int width, int height) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    p
      ..r = p.x * 255 ~/ (width - 1)
      ..g = p.y * 255 ~/ (height - 1)
      ..b = 255 - p.x * 255 ~/ (width - 1);
  }
  return image;
}

void main() {
  group('Format', () {
    group('jpeg (web)', () {
      for (final chroma in JpegChroma.values) {
        test('round trip ${chroma.name}', () {
          // Odd dimensions exercise the MCU padding blocks.
          final src = _gradient(37, 29);
          final decoded = decodeJpg(encodeJpg(src, chroma: chroma))!;
          expect(decoded.width, equals(src.width));
          expect(decoded.height, equals(src.height));
          var maxDiff = 0;
          for (final p in src) {
            final q = decoded.getPixel(p.x, p.y);
            for (var c = 0; c < 3; ++c) {
              final d = (p[c] - q[c]).abs().toInt();
              if (d > maxDiff) {
                maxDiff = d;
              }
            }
          }
          expect(maxDiff, lessThan(chroma == JpegChroma.yuv444 ? 8 : 24));
        });
      }

      for (final gray in [false, true]) {
        test('orientation is baked in${gray ? ' (grayscale)' : ''}', () {
          var src = _gradient(37, 29);
          if (gray) {
            src = src.convert(numChannels: 1);
          }
          final upright = decodeJpg(encodeJpg(src))!;
          for (var orientation = 2; orientation <= 8; ++orientation) {
            src.exif.imageIfd.orientation = orientation;
            final decoded = decodeJpg(encodeJpg(src))!;
            final expected = bakeOrientation(
                upright.clone()..exif.imageIfd.orientation = orientation);
            expect(decoded.width, equals(expected.width),
                reason: 'orientation $orientation');
            expect(decoded.height, equals(expected.height),
                reason: 'orientation $orientation');
            for (final p in expected) {
              final q = decoded.getPixel(p.x, p.y);
              expect([q.r, q.g, q.b], equals([p.r, p.g, p.b]),
                  reason: 'orientation $orientation at ${p.x},${p.y}');
            }
          }
        });
      }

      for (final chroma in JpegChroma.values) {
        test('scaled decode ${chroma.name}', () {
          final src = _gradient(37, 29);
          final bytes = encodeJpg(src, chroma: chroma);
          final full = decodeJpg(bytes)!;
          for (final scale in [2, 4, 8]) {
            final scaled = decodeJpg(bytes, scale: scale)!;
            final w = (37 + scale - 1) ~/ scale;
            final h = (29 + scale - 1) ~/ scale;
            expect(scaled.width, equals(w), reason: 'scale $scale');
            expect(scaled.height, equals(h), reason: 'scale $scale');
            // Close to the average of each scale x scale block of the full
            // size decode.
            var total = 0;
            for (final q in scaled) {
              final sum = [0, 0, 0];
              var n = 0;
              for (var y = q.y * scale; y < (q.y + 1) * scale && y < 29; ++y) {
                for (var x = q.x * scale;
                    x < (q.x + 1) * scale && x < 37;
                    ++x, ++n) {
                  final p = full.getPixel(x, y);
                  sum[0] += p.r.toInt();
                  sum[1] += p.g.toInt();
                  sum[2] += p.b.toInt();
                }
              }
              total += (sum[0] / n - q.r).abs().round() +
                  (sum[1] / n - q.g).abs().round() +
                  (sum[2] / n - q.b).abs().round();
            }
            // Subsampled chroma covers twice the area, so on this steep
            // gradient it differs more from the full resolution average.
            expect(total / (w * h * 3),
                lessThan(chroma == JpegChroma.yuv444 ? 6 : 3 + 3 * scale),
                reason: 'scale $scale');
          }
        });
      }

      test('scaled decode applies the orientation', () {
        final src = _gradient(37, 29)..exif.imageIfd.orientation = 6;
        final scaled = decodeJpg(encodeJpg(src), scale: 4)!;
        expect(scaled.width, equals(8));
        expect(scaled.height, equals(10));
      });

      test('scaled decode rejects other scales', () {
        expect(() => JpegDecoder(scale: 3), throwsArgumentError);
      });

      test('an EXIF block after the scan is still applied', () {
        // Decoding a band at a time converts rows before the EXIF block is
        // read, so the image has to be decoded again.
        final src = _gradient(37, 29);
        final plain = encodeJpg(src);
        final oriented = encodeJpg(src.clone()..exif.imageIfd.orientation = 6);
        // Move the EXIF (APP1) segment of [oriented] to just before the EOI
        // marker of [plain].
        var app1 = -1;
        for (var i = 2; i + 4 < oriented.length; ++i) {
          if (oriented[i] == 0xff && oriented[i + 1] == 0xe1) {
            app1 = i;
            break;
          }
        }
        expect(app1, greaterThan(0));
        final length = (oriented[app1 + 2] << 8) | oriented[app1 + 3];
        final segment = oriented.sublist(app1, app1 + 2 + length);
        final bytes = Uint8List.fromList(
            [...plain.sublist(0, plain.length - 2), ...segment, 0xff, 0xd9]);
        final expected = (JpegData()..read(bytes)).getImage();
        final decoded = decodeJpg(bytes)!;
        expect(decoded.width, equals(29));
        expect(decoded.height, equals(37));
        testImageEquals(decoded, expected);
      });
    });
  });
}
