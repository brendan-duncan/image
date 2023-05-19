import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() async {
  group('Format', () {
    group('jpg', () {
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
        expect(image.exif.imageIfd['XResolution'],
            equals(image2.exif.imageIfd['XResolution']));
        expect(image.exif.imageIfd['YResolution'],
            equals(image2.exif.imageIfd['YResolution']));
      });

      /*final dir = Directory('test/_data/jpg');
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

      for (var i = 1; i < 9; ++i) {
        test('exif/orientation_$i/landscape', () {
          final image = JpegDecoder().decode(
              File('test/_data/jpg/landscape_$i.jpg').readAsBytesSync())!;
          File('$testOutputPath/jpg/landscape_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));
        });

        test('exif/orientation_$i/portrait', () {
          final image = JpegDecoder().decode(
              File('test/_data/jpg/portrait_$i.jpg').readAsBytesSync())!;
          File('$testOutputPath/jpg/portrait_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));
        });
      }*/
    });
  });
}
