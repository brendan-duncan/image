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
      sourceIfd['ExtraSamples'] = 2;
      sourceIfd['Predictor'] = 2;
      sourceIfd['FillOrder'] = 2;
      sourceIfd['ColorMap'] = [0, 0, 0];
      sourceIfd['YCbCrSubSampling'] = 2;
      for (final tag in _staleTags) {
        expect(sourceIfd[tag], isNotNull, reason: tag);
      }
      final sourceExif = image.exif.toString();

      final bytes = encodeTiff(image);
      final ifd = ExifData.fromInputBuffer(InputBuffer(bytes)).imageIfd;
      for (final tag in _staleTags) {
        expect(ifd[tag], isNull, reason: tag);
      }
      expect(ifd['Software']!.toString(), 'TIFF strip regression');
      expect(image.exif.toString(), sourceExif);
      expect(imagesAreEqual(image, decodeTiff(bytes)!), isTrue);
    });

    test('writes every frame as a page', () {
      final image = _image(17, 19)..exif.imageIfd['PageNumber'] = [0, 1];
      image.exif.exifIfd['DateTimeOriginal'] = '2026:11:23 12:00:00';
      image.addFrame(_image(5, 7, numChannels: 4)..exif = image.exif);
      image.addFrame(_image(9, 3)..exif = image.exif);

      final bytes = encodeTiff(image);
      final exif = ExifData.fromInputBuffer(InputBuffer(bytes));
      for (var i = 0; i < 3; ++i) {
        final ifd = exif['ifd$i'];
        expect(ifd['SubfileType']!.toInt(), 2);
        expect(ifd['PageNumber']!.toInt(), i);
        expect(ifd['PageNumber']!.toInt(1), 3);
        expect(ifd.sub['exif']['DateTimeOriginal'].toString(),
            '2026:11:23 12:00:00');
      }

      final decoded = decodeTiff(bytes)!;
      expect(decoded.numFrames, 3);
      for (var i = 0; i < 3; ++i) {
        expect(imagesAreEqual(image.frames[i], decoded.frames[i]), isTrue);
      }

      final single = decodeTiff(encodeTiff(image, singleFrame: true))!;
      expect(single.numFrames, 1);
      expect(single.exif.imageIfd['PageNumber'], isNull);
      expect(imagesAreEqual(image, single), isTrue);
    });

    test('writes ExtraSamples for alpha channels', () {
      final image = _image(5, 7, numChannels: 4);
      final bytes = encodeTiff(image);
      final ifd = ExifData.fromInputBuffer(InputBuffer(bytes)).imageIfd;
      expect(ifd['SamplesPerPixel']!.toInt(), 4);
      expect(ifd['ExtraSamples']!.toInt(), 2);
      expect(imagesAreEqual(image, decodeTiff(bytes)!), isTrue);
    });
  });
}

const _tileTags = ['TileWidth', 'TileLength', 'TileOffsets', 'TileByteCounts'];

const _staleTags = [
  ..._tileTags,
  'ExtraSamples',
  'Predictor',
  'FillOrder',
  'ColorMap',
  'YCbCrSubSampling',
];

Image _image(int width, int height, {int numChannels = 3}) {
  final image = Image(width: width, height: height, numChannels: numChannels);
  for (final p in image) {
    p
      ..r = (p.x * 17 + p.y * 3) % 256
      ..g = (p.x * 5 + p.y * 11) % 256
      ..b = (p.x * 13 + p.y * 7) % 256
      ..a = (p.x * 29 + p.y * 19) % 256;
  }
  return image;
}
