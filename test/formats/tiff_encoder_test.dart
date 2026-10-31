import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('TIFF strip encoding', () {
    for (final size in [(1, 5), (16, 16), (17, 19), (2194, 1234)]) {
      test('${size.$1}x${size.$2} preserves pixels without tile tags', () {
        final image = _image(size.$1, size.$2);
        final bytes = encodeTiff(image);
        final ifd = ExifData.fromInputBuffer(InputBuffer(bytes)).imageIfd;

        for (final tag in _tileTags) {
          expect(ifd[tag], isNull, reason: tag);
        }
        expect(ifd['RowsPerStrip']!.toInt(), image.height);
        expect(ifd['StripByteCounts']!.toInt(), image.lengthInBytes);
        final offset = ifd['StripOffsets']!.toInt();
        expect(bytes.sublist(offset, offset + image.lengthInBytes),
            image.toUint8List());

        final decoded = decodeTiff(bytes)!;
        expect(imagesAreEqual(image, decoded), isTrue);
      });
    }

    test('removes copied tile tags without changing the source EXIF', () {
      final image = _image(17, 19);
      final sourceIfd = image.exif.imageIfd;
      sourceIfd['Software'] = 'TIFF strip regression';
      sourceIfd['TileWidth'] = 32;
      sourceIfd['TileLength'] = 32;
      sourceIfd['TileOffsets'] = [12345, 23456];
      sourceIfd['TileByteCounts'] = [4096, 4096];
      final sourceExif = image.exif.toString();

      final bytes = encodeTiff(image);
      final ifd = ExifData.fromInputBuffer(InputBuffer(bytes)).imageIfd;
      for (final tag in _tileTags) {
        expect(ifd[tag], isNull, reason: tag);
      }
      expect(ifd['Software']!.toString(), 'TIFF strip regression');
      expect(image.exif.toString(), sourceExif);
      expect(imagesAreEqual(image, decodeTiff(bytes)!), isTrue);
    });
  });
}

const _tileTags = ['TileWidth', 'TileLength', 'TileOffsets', 'TileByteCounts'];

Image _image(int width, int height) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    p
      ..r = (p.x * 17 + p.y * 3) % 256
      ..g = (p.x * 5 + p.y * 11) % 256
      ..b = (p.x * 13 + p.y * 7) % 256;
  }
  return image;
}
