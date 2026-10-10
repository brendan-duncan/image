// Malformed and malicious inputs must fail quickly and cleanly: no hangs, no
// huge allocations, and no errors other than ImageException.
//
// The inputs are built in memory, so this also runs on the web.

import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

// A JPEG holding an APP1 EXIF segment with the given TIFF structure.
Uint8List _jpegWithExif(List<int> tiff) {
  final app1 = [...'Exif'.codeUnits, 0, 0, ...tiff];
  final length = app1.length + 2;
  return Uint8List.fromList([
    0xff, 0xd8, //
    0xff, 0xe1, length >> 8, length & 0xff, ...app1,
    0xff, 0xd9,
  ]);
}

void main() {
  group('malformed input', () {
    test('EXIF IFDs that form a cycle', () {
      // Two empty IFDs that point at each other.
      final jpeg = _jpegWithExif([
        0x49, 0x49, 0x2a, 0x00, 8, 0, 0, 0, // little endian, first IFD at 8
        0, 0, 14, 0, 0, 0, // 0 entries, next IFD at 14
        0, 0, 8, 0, 0, 0, // 0 entries, next IFD at 8
      ]);
      final exif = decodeJpgExif(jpeg);
      expect(exif, isNotNull);
      expect(exif!.directories.length, lessThanOrEqualTo(2));
    });
  });
}
