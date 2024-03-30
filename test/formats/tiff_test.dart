import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('tiff', () {
      test('deflate.tif', () async {
        final bytes = File('test/_data/tiff/deflate.tif').readAsBytesSync();
        final i0 = decodeTiff(bytes);
        expect(i0, isNotNull);
        File('$testOutputPath/tif/deflate.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i0!));
      });

      test('16bit colormap', () async {
        final bytes = File('test/_data/tiff/CNSW_crop.tif').readAsBytesSync();
        final i1 = decodeTiff(bytes);
        expect(i1, isNotNull);
        final o1 = i1!.convert(format: Format.uint8);
        File('$testOutputPath/tif/CNSW_crop.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(o1));
      });

      test('encode', () async {
        final i0 = Image(width: 256, height: 256);
        for (final p in i0) {
          p
            ..r = p.x
            ..g = p.y;
        }
        await encodeTiffFile('$testOutputPath/tif/colors.tif', i0);
        final i1 = await decodeTiffFile('$testOutputPath/tif/colors.tif');
        expect(i1, isNotNull);
        expect(i1!.width, equals(i0.width));
        expect(i1.height, equals(i0.height));
        for (final p in i1) {
          expect(p.r, equals(p.x));
          expect(p.g, equals(p.y));
          expect(p.b, equals(0));
          expect(p.a, equals(255));
        }

        final i3p =
            Image(width: 256, height: 256, numChannels: 4, withPalette: true);
        for (var i = 0; i < 256; ++i) {
          i3p.palette!.setRgb(i, i, i, i);
        }
        for (final p in i3p) {
          p.index = p.x;
        }
        await encodeTiffFile('$testOutputPath/tif/palette.tif', i3p);
        final i3p2 = await decodeTiffFile('$testOutputPath/tif/palette.tif');
        expect(i3p2, isNotNull);
        expect(i3p2!.width, equals(i3p.width));
        expect(i3p2.height, equals(i3p.height));
        expect(i3p2.hasPalette, isTrue);
        for (final p in i3p2) {
          expect(p.r, equals(p.x));
          expect(p.g, equals(p.x));
          expect(p.b, equals(p.x));
          expect(p.a, equals(255));
        }

        final img = (await decodeJpgFile('test/_data/jpg/big_buck_bunny.jpg'))!;
        await encodeTiffFile('$testOutputPath/tif/big_buck_bunny.tif', img);
      });

      const name = 'cmyk';
      test(name, () {
        final bytes = File('test/_data/tiff/$name.tif').readAsBytesSync();
        final i0 = decodeTiff(bytes)!;
        final i1 = i0.isHdrFormat ? i0.convert(format: Format.uint8) : i0;
        File('$testOutputPath/tif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i1));
      });

      final dir = Directory('test/_data/tiff');
      final files = dir.listSync();

      group('getInfo', () {
        for (var f in files.whereType<File>()) {
          if (!f.path.endsWith('.tif')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final bytes = f.readAsBytesSync();

            final info = TiffDecoder().startDecode(bytes);
            expect(info, isNotNull);
            final expectedInfo = _expectedInfo[name];
            if (info != null && expectedInfo != null) {
              expect(info.width, equals(expectedInfo['width']));
              expect(info.height, equals(expectedInfo['height']));
              expect(info.bigEndian, equals(expectedInfo['bigEndian']));
              final images = expectedInfo['images'] as List;
              expect(info.images.length, equals(images.length));
              for (var i = 0; i < info.images.length; ++i) {
                final i1 = info.images[i];
                final i2 = images[i] as Map;
                expect(i1.width, equals(i2['width']));
                expect(i1.height, equals(i2['height']));
                expect(i1.photometricType, equals(i2['photometricType']));
                expect(i1.compression, equals(i2['compression']));
                expect(i1.bitsPerSample, equals(i2['bitsPerSample']));
                expect(i1.samplesPerPixel, equals(i2['samplesPerPixel']));
                expect(i1.imageType, equals(i2['imageType']));
                expect(i1.tiled, equals(i2['tiled']));
                expect(i1.tileWidth, equals(i2['tileWidth']));
                expect(i1.tileHeight, equals(i2['tileHeight']));
                expect(i1.predictor, equals(i2['predictor']));
                if (i1.colorMap == null) {
                  expect(i2['colorMap'], isNull);
                } else {
                  expect(i2['colorMap'], isNotNull);
                  final cm = i2['colorMap'] as List;
                  expect(i1.colorMap!, equals(cm));
                }
              }
            }
          });
        }
      });

      group('decode', () {
        for (var f in files.whereType<File>()) {
          if (!f.path.endsWith('.tif')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final bytes = f.readAsBytesSync();
            final image = decodeTiff(bytes);
            expect(image, isNotNull);

            final i0 = image!;
            final i1 = i0.isHdrFormat ? i0.convert(format: Format.uint8) : i0;

            File('$testOutputPath/tif/$name.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodePng(i1));

            final tif = encodeTiff(image);
            File('$testOutputPath/tif/$name.tif')
              ..createSync(recursive: true)
              ..writeAsBytesSync(tif);

            final i2 = decodeTiff(tif);
            expect(i2, isNotNull);
            expect(i2!.width, equals(image.width));
            expect(i2.height, equals(image.height));

            final i3 = i2.isHdrFormat ? i2.convert(format: Format.uint8) : i2;
            File('$testOutputPath/tif/$name-2.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodePng(i3));
          });
        }
      });
    });
  });
}

const _expectedInfo = {
  'aspect32float.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
  'bitonal_lzw.tif': {
    'width': 100,
    'height': 100,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 100,
        'height': 100,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 5,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 100,
        'tileHeight': 100,
        'predictor': 1,
      },
    ],
  },
  'bitonal_none.tif': {
    'width': 100,
    'height': 100,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 100,
        'height': 100,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 1,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 100,
        'tileHeight': 100,
        'predictor': 1,
      },
    ],
  },
  'bitonal_zip.tif': {
    'width': 100,
    'height': 100,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 100,
        'height': 100,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 8,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 100,
        'tileHeight': 100,
        'predictor': 1,
      },
    ],
  },
  'ccittt_t4_1d_nofill.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 3,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 225,
        'predictor': 1,
      },
    ],
  },
  'ccitt_t4_1d_fill.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 3,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 225,
        'predictor': 1,
      },
    ],
  },
  'ccitt_t4_2d_fill.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 3,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 225,
        'predictor': 1,
      },
    ],
  },
  'ccitt_t4_2d_nofill.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 3,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 225,
        'predictor': 1,
      },
    ],
  },
  'ccitt_t6.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.whiteIsZero,
        'compression': 4,
        'bitsPerSample': 1,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.bilevel,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 225,
        'predictor': 1,
      },
    ],
  },
  'cmyk.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.cmyk,
        'compression': 5,
        'bitsPerSample': 8,
        'samplesPerPixel': 4,
        'imageType': TiffImageType.generic,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 27,
        'predictor': 1,
      },
    ],
  },
  'dtm32float.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
  'dtm64float.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 64,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
  'dtm_test.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
  'float16.tif': {
    'width': 420,
    'height': 420,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 420,
        'height': 420,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 1,
        'bitsPerSample': 16,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': false,
        'tileWidth': 420,
        'tileHeight': 420,
        'predictor': 1,
      },
    ],
  },
  'float1x32.tif': {
    'width': 420,
    'height': 420,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 420,
        'height': 420,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 420,
        'tileHeight': 420,
        'predictor': 1,
      },
    ],
  },
  'float32.tif': {
    'width': 420,
    'height': 420,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 420,
        'height': 420,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': false,
        'tileWidth': 420,
        'tileHeight': 420,
        'predictor': 1,
      },
    ],
  },
  'flow16int.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 16,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
  'globe.tif': {
    'width': 256,
    'height': 256,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 256,
        'height': 256,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 5,
        'bitsPerSample': 8,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': false,
        'tileWidth': 256,
        'tileHeight': 256,
        'predictor': 2,
      },
    ],
  },
  'lzw_strips.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 5,
        'bitsPerSample': 8,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 9,
        'predictor': 2,
      },
    ],
  },
  'lzw_tiled.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 5,
        'bitsPerSample': 8,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': true,
        'tileWidth': 256,
        'tileHeight': 256,
        'predictor': 2,
      },
    ],
  },
  'small.tif': {
    'width': 300,
    'height': 225,
    'bigEndian': false,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 300,
        'height': 225,
        'photometricType': TiffPhotometricType.rgb,
        'compression': 1,
        'bitsPerSample': 8,
        'samplesPerPixel': 3,
        'imageType': TiffImageType.rgb,
        'tiled': false,
        'tileWidth': 300,
        'tileHeight': 9,
        'predictor': 1,
      },
    ],
  },
  'tca32int.tif': {
    'width': 10,
    'height': 8,
    'bigEndian': true,
    'images': <Map<String, Object>>[
      <String, Object>{
        'width': 10,
        'height': 8,
        'photometricType': TiffPhotometricType.blackIsZero,
        'compression': 1,
        'bitsPerSample': 32,
        'samplesPerPixel': 1,
        'imageType': TiffImageType.gray,
        'tiled': false,
        'tileWidth': 10,
        'tileHeight': 8,
        'predictor': 1,
      },
    ],
  },
};
