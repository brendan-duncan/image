import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void JpegTest() {
  group('Jpeg', () {
    test('decode', () {
      final fb = File('test/data/jpg/buck_24.jpg').readAsBytesSync();
      final image = JpegDecoder().decodeImage(fb)!;
      expect(image.width, equals(300));
      expect(image.height, equals(186));
      expect(image.numChannels, equals(3));
      File('$tmpPath/out/jpg/decode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));
    });

    test('encode', () {
      final fb = File('test/data/jpg/buck_24.jpg').readAsBytesSync();
      final image = JpegDecoder().decodeImage(fb)!;
      File('$tmpPath/out/jpg/encode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeJpg(image));
    });

    test('progressive', () {
      final fb = File('test/data/jpg/progress.jpg').readAsBytesSync();
      final image = JpegDecoder().decodeImage(fb)!;
      expect(image.width, 341);
      expect(image.height, 486);
      File('$tmpPath/out/jpg/progressive.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));
    });

    test('exif', () {
      final fb = File('test/data/jpg/big_buck_bunny.jpg').readAsBytesSync();
      final image = JpegDecoder().decodeImage(fb)!;
      image.exif.imageIfd['XResolution'] = [300,1];
      image.exif.imageIfd['YResolution'] = [300,1];
      var jpg = JpegEncoder().encodeImage(image);
      final image2 = JpegDecoder().decodeImage(jpg)!;
      expect(image.exif.imageIfd['XResolution'],
          equals(image2.exif.imageIfd['XResolution']));
      expect(image.exif.imageIfd['YResolution'],
          equals(image2.exif.imageIfd['YResolution']));
    });

    final dir = Directory('test/data/jpg');
    final files = dir.listSync(recursive: true);
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.jpg')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final bytes = f.readAsBytesSync();
        expect(JpegDecoder().isValidFile(bytes), equals(true));

        final image = JpegDecoder().decodeImage(bytes)!;
        final outJpg = JpegEncoder().encodeImage(image);
        File('$tmpPath/out/jpg/$name.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(outJpg);

        // Make sure we can read what we just wrote.
        final image2 = JpegDecoder().decodeImage(outJpg)!;
        expect(image.width, equals(image2.width));
        expect(image.height, equals(image2.height));
      });
    }

    for (var i = 1; i < 9; ++i) {
      test('exif/orientation_$i/landscape', () {
        final image = JpegDecoder().decodeImage(
            File('test/data/jpg/landscape_$i.jpg').readAsBytesSync())!;
        File('$tmpPath/out/jpg/landscape_$i.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(JpegEncoder().encodeImage(image));
      });

      test('exif/orientation_$i/portrait', () {
        final image = JpegDecoder().decodeImage(
            File('test/data/jpg/portrait_$i.jpg').readAsBytesSync())!;
        File('$tmpPath/out/jpg/portrait_$i.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(JpegEncoder().encodeImage(image));
      });
    }
  });
}
