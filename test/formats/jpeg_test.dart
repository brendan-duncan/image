import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() async {
  group('Format', () {
    group('jpg', () {
      // Re-declares the dimensions in the SOF header of a small valid JPEG,
      // producing a tiny file that claims to be a huge image.
      Uint8List jpgWithSize(int width, int height, {int components = 3}) {
        final jpg = encodeJpg(Image(width: 8, height: 8, numChannels: 3));
        for (var i = 0; i < jpg.length - 9; ++i) {
          if (jpg[i] == 0xff && jpg[i + 1] == 0xc0) {
            jpg[i + 5] = height >> 8;
            jpg[i + 6] = height & 0xff;
            jpg[i + 7] = width >> 8;
            jpg[i + 8] = width & 0xff;
            if (components != 3) {
              jpg[i + 9] = components;
            }
            return jpg;
          }
        }
        throw StateError('SOF0 not found');
      }

      test('rejects dimensions over maxPixels', () {
        final jpg = jpgWithSize(65535, 65535);
        final sw = Stopwatch()..start();
        expect(() => decodeJpg(jpg), throwsA(isA<ImageException>()));
        expect(() => decodeImage(jpg), throwsA(isA<ImageException>()));
        expect(sw.elapsedMilliseconds, lessThan(1000));

        expect(() => decodeJpg(jpgWithSize(101, 100), maxPixels: 10000),
            throwsA(isA<ImageException>()));
        final image = decodeJpg(jpgWithSize(100, 100), maxPixels: 10000);
        expect(image?.width, equals(100));
        expect(image?.height, equals(100));
      });

      test('defaultMaxPixels', () {
        final saved = JpegDecoder.defaultMaxPixels;
        addTearDown(() => JpegDecoder.defaultMaxPixels = saved);
        JpegDecoder.defaultMaxPixels = 64 * 64;
        expect(() => decodeImage(jpgWithSize(65, 64)),
            throwsA(isA<ImageException>()));
        expect(decodeImage(jpgWithSize(64, 64))?.width, equals(64));
      });

      test('startDecode does not allocate for huge dimensions', () {
        final decoder = JpegDecoder();
        final info = decoder.startDecode(jpgWithSize(65535, 65535));
        expect(info?.width, equals(65535));
        expect(info?.height, equals(65535));
        expect(() => decoder.decodeFrame(0), throwsA(isA<ImageException>()));
      });

      test('rejects invalid frame headers', () {
        expect(
            () => decodeJpg(jpgWithSize(0, 8)), throwsA(isA<ImageException>()));
        expect(() => decodeJpg(jpgWithSize(8, 8, components: 0)),
            throwsA(isA<ImageException>()));
      });

      test('inject new exif', () {
        final fb = File('test/_data/jpg/jpeg444.jpg').readAsBytesSync();
        final exif = ExifData();
        exif.imageIfd['xResolution'] = [300, 1];
        exif.imageIfd['yResolution'] = [300, 1];
        final jpg = injectJpgExif(fb, exif);
        expect(jpg, isNotNull);
        final image2 = JpegDecoder().decode(jpg!);
        expect(image2, isNotNull);
        expect(
          exif.imageIfd['XResolution'],
          equals(image2!.exif.imageIfd['XResolution']),
        );
        expect(
          exif.imageIfd['YResolution'],
          equals(image2.exif.imageIfd['YResolution']),
        );
      });

      test('inject replacement exif', () {
        final fb = File('test/_data/jpg/big_buck_bunny.jpg').readAsBytesSync();
        final exif = ExifData();
        exif.imageIfd['xResolution'] = [300, 1];
        exif.imageIfd['yResolution'] = [300, 1];
        final jpg = injectJpgExif(fb, exif);
        expect(jpg, isNotNull);
        final image2 = JpegDecoder().decode(jpg!);
        expect(image2, isNotNull);
        expect(
          exif.imageIfd['XResolution'],
          equals(image2!.exif.imageIfd['XResolution']),
        );
        expect(
          exif.imageIfd['YResolution'],
          equals(image2.exif.imageIfd['YResolution']),
        );
      });

      test('png icc_profile', () async {
        final bytes = File('test/_data/png/iCCP.png').readAsBytesSync();
        final image = PngDecoder().decode(bytes)!;
        encodeJpgFile('$testOutputPath/jpg/png_icc_profile_data.jpg', image);
      });

      test('icc_profile', () async {
        final jpg = await File(
          'test/_data/jpg/icc_profile_data.jpg',
        ).readAsBytes();
        final img = decodeJpg(jpg);
        expect(img, isNotNull);
        encodeJpgFile('$testOutputPath/jpg/icc_profile_data.jpg', img!);
      });

      test('exif', () async {
        final jpg = await File('test/_data/jpg/kodak-dc210.jpg').readAsBytes();
        final img = decodeJpg(jpg);
        expect(img, isNotNull);
        expect(img!.hasExif, isTrue);
      });

      test('decode / inject Exif', () async {
        final jpg = await File('test/_data/jpg/buck_24.jpg').readAsBytes();
        final exif = decodeJpgExif(jpg);
        expect(exif, isNotNull);
        expect(exif!.imageIfd['Orientation']?.toInt(), equals(1));

        exif.imageIfd['Orientation'] = 4;
        expect(exif.imageIfd['Orientation']?.toInt(), equals(4));

        final jpg2 = injectJpgExif(jpg, exif);
        expect(jpg2, isNotNull);
        File('$testOutputPath/jpg/inject_exif.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(jpg2!);

        final image = JpegDecoder().decode(jpg2);
        expect(image, isNotNull);
        encodeJpgFile('$testOutputPath/jpg/inject_exif2.jpg', image!);
      });

      test('decode', () {
        final fb = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        expect(image.width, equals(300));
        expect(image.height, equals(186));
        expect(image.numChannels, equals(3));
        File('$testOutputPath/jpg/decode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });

      test('encode (default 4:4:4 chroma)', () {
        final fb = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        File('$testOutputPath/jpg/encode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(image));
      });

      test('encode (4:2:0 chroma)', () {
        final fb = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        File('$testOutputPath/jpg/encode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(image, chroma: JpegChroma.yuv420));
      });

      test('progressive', () {
        final fb = File('test/_data/jpg/progress.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        expect(image.width, 341);
        expect(image.height, 486);
        File('$testOutputPath/jpg/progressive.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });

      test('exif', () {
        final fb = File('test/_data/jpg/big_buck_bunny.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        image.exif.imageIfd['XResolution'] = [300, 1];
        image.exif.imageIfd['YResolution'] = [300, 1];
        final jpg = JpegEncoder().encode(image);
        final image2 = JpegDecoder().decode(jpg)!;
        expect(
          image.exif.imageIfd['XResolution'],
          equals(image2.exif.imageIfd['XResolution']),
        );
        expect(
          image.exif.imageIfd['YResolution'],
          equals(image2.exif.imageIfd['YResolution']),
        );
      });

      final dir = Directory('test/_data/jpg');
      final files = dir.listSync(recursive: true);
      for (var f in files.whereType<File>()) {
        if (!f.path.endsWith('.jpg')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () async {
          final bytes = f.readAsBytesSync();
          expect(JpegDecoder().isValidFile(bytes), equals(true));

          final image = JpegDecoder().decode(bytes)!;
          final outJpg = JpegEncoder().encode(image);
          File('$testOutputPath/jpg/$name')
            ..createSync(recursive: true)
            ..writeAsBytesSync(outJpg);

          // Make sure we can read what we just wrote.
          final image2 = JpegDecoder().decode(outJpg)!;
          expect(image.width, equals(image2.width));
          expect(image.height, equals(image2.height));
        });
      }

      // https://github.com/brendan-duncan/image/issues/805
      test('restart marker before EOI', () {
        final src = Image(width: 32, height: 32)
          ..clear(ColorRgb8(200, 100, 50));
        final jpg = JpegEncoder().encode(src);
        expect(jpg[jpg.length - 2], equals(0xff));
        expect(jpg[jpg.length - 1], equals(0xd9));

        for (var rst = 0xd0; rst <= 0xd7; ++rst) {
          final bytes = [
            ...jpg.sublist(0, jpg.length - 2),
            0xff, rst, // RSTn
            0xff, 0xd9, // EOI
          ];
          final image = JpegDecoder().decode(Uint8List.fromList(bytes))!;
          expect(image.width, equals(32));
          expect(image.height, equals(32));
          final p = image.getPixel(16, 16);
          expect(p.r, closeTo(200, 3));
          expect(p.g, closeTo(100, 3));
          expect(p.b, closeTo(50, 3));
        }
      });

      for (var i = 1; i < 9; ++i) {
        test('exif/orientation_$i/landscape', () {
          final image = JpegDecoder().decode(
            File('test/_data/jpg/landscape_$i.jpg').readAsBytesSync(),
          )!;
          File('$testOutputPath/jpg/landscape_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));
        });

        test('exif/orientation_$i/portrait', () {
          final image = JpegDecoder().decode(
            File('test/_data/jpg/portrait_$i.jpg').readAsBytesSync(),
          )!;
          File('$testOutputPath/jpg/portrait_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));
        });
      }
    });
  });
}
