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
        final jpg = encodeJpg(Image(width: 8, height: 8));
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
        final jpg = encodeJpg(image);
        File('$testOutputPath/jpg/encode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(jpg);

        final decoded = JpegDecoder().decode(jpg)!;
        expect(decoded.width, equals(image.width));
        expect(decoded.height, equals(image.height));
        expect(decoded.numChannels, equals(3));
        // Re-encoding at the default quality loses very little.
        expect(_meanAbsDiff(image, decoded), lessThan(1.5));
        expectImagesClose(image, decoded, tolerance: 12);
      });

      test('encode (4:2:0 chroma)', () {
        final fb = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();
        final image = JpegDecoder().decode(fb)!;
        final jpg = encodeJpg(image, chroma: JpegChroma.yuv420);
        File('$testOutputPath/jpg/encode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(jpg);

        final decoded = JpegDecoder().decode(jpg)!;
        expect(decoded.width, equals(image.width));
        expect(decoded.height, equals(image.height));
        expect(decoded.numChannels, equals(3));
        final diff420 = _meanAbsDiff(image, decoded);
        expect(diff420, lessThan(4));

        // Subsampled chroma is close to, but measurably worse than, 4:4:4.
        final decoded444 = JpegDecoder().decode(encodeJpg(image))!;
        expect(diff420, greaterThan(_meanAbsDiff(image, decoded444)));
        expect(_meanAbsDiff(decoded444, decoded), greaterThan(0.5));
        expect(jpg.length, lessThan(encodeJpg(image).length));
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

      // Each file stores the same photo under a different EXIF orientation,
      // with the pixels transformed to match, so every decode is upright.
      // The _1 files were saved without an ICC profile and are uniformly
      // brighter (a mean difference of about 15), so they get a looser bound;
      // a wrongly mirrored or flipped decode differs by 40 or more.
      void expectUpright(Image image, String kind, int i) {
        final ref1 = decodeJpg(
          File('test/_data/jpg/${kind}_1.jpg').readAsBytesSync(),
        )!;
        final ref2 = decodeJpg(
          File('test/_data/jpg/${kind}_2.jpg').readAsBytesSync(),
        )!;
        expect(image.width, equals(ref1.width));
        expect(image.height, equals(ref1.height));
        expect(_meanAbsDiff(ref1, image), lessThan(20));
        if (i > 1) {
          expect(_meanAbsDiff(ref2, image), lessThan(6));
        }
      }

      for (var i = 1; i < 9; ++i) {
        test('exif/orientation_$i/landscape', () {
          final image = JpegDecoder().decode(
            File('test/_data/jpg/landscape_$i.jpg').readAsBytesSync(),
          )!;
          File('$testOutputPath/jpg/landscape_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));

          expect(image.width, greaterThan(image.height));
          expectUpright(image, 'landscape', i);
        });

        test('exif/orientation_$i/portrait', () {
          final image = JpegDecoder().decode(
            File('test/_data/jpg/portrait_$i.jpg').readAsBytesSync(),
          )!;
          File('$testOutputPath/jpg/portrait_$i.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(JpegEncoder().encode(image));

          expect(image.height, greaterThan(image.width));
          expectUpright(image, 'portrait', i);
        });
      }
    });

    test('encodeJpg does not modify an RGBA source image', () {
      final image = Image(width: 16, height: 16, numChannels: 4)
        ..clear(ColorRgba8(200, 100, 50, 128));
      final original = image.clone();
      encodeJpg(image);
      testImageEquals(image, original);
    });

    test('JpegData.read releases DCT coefficients', () {
      final bytes = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();
      final jpeg = JpegData()..read(bytes);
      for (final component in jpeg.frame!.components.values) {
        expect(component.coefficients, isEmpty);
      }
      expect(jpeg.getImage().width, equals(jpeg.width));
    });

    test('1/8 scale decode of progressive and baseline images', () {
      for (final name in [
        'jpg-progressive.jpg',
        'testprog.jpg',
        'buck_24.jpg'
      ]) {
        final bytes = File('test/_data/jpg/$name').readAsBytesSync();
        final full = decodeJpg(bytes)!;
        final scaled = decodeJpg(bytes, scale: 8)!;
        expect(scaled.width, equals((full.width + 7) ~/ 8), reason: name);
        expect(scaled.height, equals((full.height + 7) ~/ 8), reason: name);
        // Each pixel is close to the average of its 8x8 block.
        var total = 0.0;
        for (final q in scaled) {
          var sum = 0.0;
          var n = 0;
          for (var y = q.y * 8; y < q.y * 8 + 8 && y < full.height; ++y) {
            for (var x = q.x * 8; x < q.x * 8 + 8 && x < full.width; ++x) {
              sum += full.getPixel(x, y).luminance;
              ++n;
            }
          }
          total += (sum / n - q.luminance).abs();
        }
        expect(total / (scaled.width * scaled.height), lessThan(8),
            reason: name);
      }
    });
  });
}

/// The mean absolute difference of the r, g and b channels of [a] and [b].
double _meanAbsDiff(Image a, Image b) {
  expect(b.width, equals(a.width));
  expect(b.height, equals(a.height));
  var sum = 0.0;
  for (final p in a) {
    final q = b.getPixel(p.x, p.y);
    sum += (p.r - q.r).abs() + (p.g - q.g).abs() + (p.b - q.b).abs();
  }
  return sum / (a.width * a.height * 3);
}
