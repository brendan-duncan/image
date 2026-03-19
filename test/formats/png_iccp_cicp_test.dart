// Tests for PNG decoding with embedded ICC profile (iCCP chunk) and
// colour information chunk (cICP), as produced by Apple devices saving
// Display P3 images.
//
// Regression tests for:
//   1. RGBA PNG files that carry an iCCP + cICP chunk should decode with the
//      exact pixel values stored in the IDAT data.
//   2. The cICP chunk (Coding-independent code points, PNG spec §cICP-chunk)
//      must be read and stored instead of silently discarded.  Before the fix
//      the 'cICP' chunk fell through to the `default` branch in the switch
//      statement and was skipped without recording any information.

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Format', () {
    group('png_iccp_cicp', () {
      // The test fixture is a 4×4 RGBA PNG that contains:
      //   - an iCCP chunk  (fake Display-P3 ICC profile, deflate-compressed)
      //   - a cICP chunk   ([12, 13, 0, 1] – Display P3 / sRGB transfer)
      //
      // Expected pixel layout (row-major, RGBA):
      //   row 0: (255,0,0,255) (0,255,0,255) (0,0,255,255)  (255,255,255,255)
      //   row 1: (0,0,0,255)   (128,128,128,255) (255,255,0,255) (0,0,0,0)
      //   row 2: (0,255,255,255) (255,0,255,255) (255,128,0,255) (200,0,0,128)
      //   row 3: (0,0,0,0) × 4
      test('decodes pixel values correctly (not all-black)', () async {
        final bytes =
            await File('test/_data/png/rgba_iccp_cicp.png').readAsBytes();
        final image = decodePng(bytes);
        expect(image, isNotNull, reason: 'PNG should be decodable');
        expect(image!.width, equals(4));
        expect(image.height, equals(4));
        expect(image.numChannels, equals(4), reason: 'should be RGBA');

        void checkPixel(int x, int y, int r, int g, int b, int a) {
          final p = image.getPixel(x, y);
          expect(p.r.toInt(), equals(r), reason: 'pixel ($x,$y) red channel');
          expect(p.g.toInt(), equals(g), reason: 'pixel ($x,$y) green channel');
          expect(p.b.toInt(), equals(b), reason: 'pixel ($x,$y) blue channel');
          expect(p.a.toInt(), equals(a), reason: 'pixel ($x,$y) alpha channel');
        }

        // Row 0 – fully-opaque colour pixels
        checkPixel(0, 0, 255, 0, 0, 255); // red
        checkPixel(1, 0, 0, 255, 0, 255); // green
        checkPixel(2, 0, 0, 0, 255, 255); // blue
        checkPixel(3, 0, 255, 255, 255, 255); // white

        // Row 1 – mixed opacity
        checkPixel(0, 1, 0, 0, 0, 255); // black opaque
        checkPixel(1, 1, 128, 128, 128, 255); // grey
        checkPixel(2, 1, 255, 255, 0, 255); // yellow
        checkPixel(3, 1, 0, 0, 0, 0); // fully transparent

        // Row 2 – more colours
        checkPixel(0, 2, 0, 255, 255, 255); // cyan
        checkPixel(1, 2, 255, 0, 255, 255); // magenta
        checkPixel(2, 2, 255, 128, 0, 255); // orange
        checkPixel(3, 2, 200, 0, 0, 128); // semi-transparent red

        // Row 3 – all transparent
        for (var x = 0; x < 4; x++) {
          checkPixel(x, 3, 0, 0, 0, 0);
        }
      });

      test('iCCP name is preserved in iccProfile metadata', () async {
        final bytes =
            await File('test/_data/png/rgba_iccp_cicp.png').readAsBytes();
        final image = decodePng(bytes)!;
        expect(image.iccProfile, isNotNull,
            reason: 'ICC profile should be stored as metadata');
        expect(image.iccProfile!.name, equals('Display P3'));
      });

      // RED/GREEN test for the cICP chunk fix.
      //
      // Before the fix: the cICP chunk was an unknown chunk and fell through
      // to `default: skip` – info.cicpData was never populated (null).
      //
      // After the fix: the 'cICP' case reads the four bytes and stores them in
      // info.cicpData, which is then accessible via PngDecoder.info.
      test('cICP chunk is parsed and stored (not silently discarded)',
          () async {
        final bytes =
            await File('test/_data/png/rgba_iccp_cicp.png').readAsBytes();
        final decoder = PngDecoder()..startDecode(bytes);

        // These assertions FAIL before the fix and PASS after the fix.
        expect(decoder.info.cicpData, isNotNull,
            reason: 'cICP chunk should be stored, not discarded');

        final cicp = decoder.info.cicpData!;
        // Our test PNG has cICP = [12, 13, 0, 1] (Display P3, sRGB transfer,
        // identity matrix, full range).
        expect(cicp.colourPrimaries, equals(12),
            reason: '12 = Display P3 colour primaries');
        expect(cicp.transferCharacteristics, equals(13),
            reason: '13 = sRGB / Display P3 transfer function');
        expect(cicp.matrixCoefficients, equals(0),
            reason: '0 = identity / RGB (required for still images)');
        expect(cicp.videoFullRangeFlag, equals(1),
            reason: '1 = full range (0–255)');
      });

      // Round-trip test: encode with cICP, decode, verify the data is
      // preserved.
      test('cICP round-trips through encoder', () async {
        final bytes =
            await File('test/_data/png/rgba_iccp_cicp.png').readAsBytes();
        final original = decodePng(bytes)!;

        // Encode with the cICP metadata
        const expectedCicp = PngCicpData(
          colourPrimaries: 12,
          transferCharacteristics: 13,
          matrixCoefficients: 0,
          videoFullRangeFlag: 1,
        );
        final encoded = Uint8List.fromList(
          PngEncoder(cicpData: expectedCicp).encode(original),
        );

        // Decode the re-encoded PNG
        final reDecoder = PngDecoder()..startDecode(encoded);

        expect(reDecoder.info.cicpData, isNotNull,
            reason: 'cICP should survive a PNG encode/decode round-trip');
        expect(reDecoder.info.cicpData, equals(expectedCicp));
      });
    });
  });
}
