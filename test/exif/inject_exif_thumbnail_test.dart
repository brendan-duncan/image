import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:image/src/formats/jpeg/jpeg_util.dart';
import 'package:test/test.dart';

/// Returns the set of JPEG marker bytes (e.g. 0xe0 for APP0) present in the
/// segment list of [jpeg], scanning from the SOI up to the start of scan data.
Set<int> _segmentMarkers(Uint8List jpeg) {
  final markers = <int>{};
  var i = 2; // skip SOI
  while (i + 4 <= jpeg.length) {
    if (jpeg[i] != 0xff) {
      break;
    }
    final marker = jpeg[i + 1];
    // SOS (0xda) starts the entropy-coded scan; EOI (0xd9) ends the image.
    if (marker == 0xda || marker == 0xd9) {
      break;
    }
    markers.add(marker);
    final len = (jpeg[i + 2] << 8) | jpeg[i + 3];
    i += 2 + len;
  }
  return markers;
}

void main() {
  // Files that carry a JFIF (APP0) header before their EXIF (APP1) block and
  // embed an IFD1 thumbnail — the exact shape that regressed in
  // https://github.com/brendan-duncan/image/issues/793
  const files = [
    'test/_data/jpg/icc_profile_Upper_Left.jpg',
    'test/_data/jpg/icc_profile_data.jpg',
  ];

  for (final path in files) {
    group('injectExif preserves APP0 and thumbnail: $path', () {
      final orig = File(path).readAsBytesSync();
      final exif = JpegUtil().decodeExif(orig)!;

      test('thumbnail payload is captured on read', () {
        final thumb = exif.thumbnailData;
        expect(thumb, isNotNull, reason: 'IFD1 thumbnail should be captured');
        expect(thumb!.length, greaterThan(0));
        // An embedded EXIF thumbnail is itself a JPEG (starts with SOI).
        expect(thumb[0], 0xff);
        expect(thumb[1], 0xd8);
      });

      test('round-trip keeps the JFIF APP0 segment and the thumbnail', () {
        // Sanity: the source really does have the segments under test.
        expect(_segmentMarkers(orig), contains(0xe0),
            reason: 'source must have a JFIF APP0 segment');

        // Minimal edit, exactly like the issue's reproduction.
        exif.imageIfd['DateTime'] = '2017:12:23 12:39:48';

        final out = JpegUtil().injectExif(exif, orig);
        expect(out, isNotNull);

        // Cause 1: the JFIF APP0 (and everything before the EXIF block) must
        // survive the round-trip rather than being silently dropped.
        expect(_segmentMarkers(out!), contains(0xe0),
            reason: 'APP0 must be preserved through injectExif');

        // Cause 2: the thumbnail payload must round-trip byte-for-byte, and the
        // ThumbnailOffset/Length tags must point at it (not dangle).
        final decoded = JpegUtil().decodeExif(out)!;
        expect(decoded.thumbnailData, isNotNull,
            reason: 'thumbnail must survive the round-trip');
        expect(decoded.thumbnailData, orderedEquals(exif.thumbnailData!));

        // The edited tag still round-trips.
        expect(decoded.imageIfd['DateTime']?.toString(),
            '2017:12:23 12:39:48');
      });
    });
  }

  test('write() drops ThumbnailOffset/Length when no payload is available', () {
    // An ExifData with IFD1 offset/length tags but no captured thumbnail bytes
    // must not emit dangling pointers — the tags should be dropped instead.
    final exif = ExifData();
    exif.imageIfd['Make'] = 'test';
    exif.thumbnailIfd[0x0201] = IfdValueLong(9999); // ThumbnailOffset
    exif.thumbnailIfd[0x0202] = IfdValueLong(1234); // ThumbnailLength
    // thumbnailData intentionally left null.

    final out = OutputBuffer(bigEndian: true);
    exif.write(out);
    final reread = ExifData.fromInputBuffer(
        InputBuffer(out.getBytes(), bigEndian: true));

    expect(reread.thumbnailData, isNull);
    expect(reread.thumbnailIfd.containsKey(0x0201), isFalse);
    expect(reread.thumbnailIfd.containsKey(0x0202), isFalse);
  });
}
