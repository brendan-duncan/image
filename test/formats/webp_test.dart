import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    const path = 'test/_data/webp';

    test('webp invalid decode', () async {
      final webp =
          decodeWebP(File('$path/invalid_last_row.webp').readAsBytesSync());
      expect(webp, isNotNull);
      expect(webp!.getPixel(0, webp.height - 2).a, isNot(0));
      // guard against bug where the last decoded row is empty
      expect(webp.getPixel(0, webp.height - 1).a, isNot(0));
    });

    const files = [
      'error2',
      'fig_sharp',
      'fig_noisy',
      'dem',
      'error',
      '1_webp_ll',
      '1_webp_a',
      '2_webp_ll',
      '2_webp_a',
      '3_webp_ll',
      '3_webp_a',
      '4_webp_ll',
      '4_webp_a',
      '5_webp_ll',
      '5_webp_a',
      'test',
    ];

    group('decode webp', () {
      for (var file in files) {
        test(file, () async {
          final webp = decodeWebP(File('$path/$file.webp').readAsBytesSync());
          expect(webp, isNotNull);
          File('$testOutputPath/webp/$file.webp')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodeWebP(webp!));
          if (File('$path/$file.png').existsSync()) {
            final png = decodePng(File('$path/$file.png').readAsBytesSync())!;
            final png4 = png.numChannels != 4
                ? png.convert(numChannels: 4, alpha: 255)
                : png;
            testImageEquals(webp, png4);
          }
        });
      }
    });

    group('webp', () {
      test('exif', () async {
        final webp = await decodeWebPFile('test/_data/webp/buck_24.webp');
        expect(webp, isNotNull);
        expect(webp!.exif.imageIfd['Orientation'], IfdValueShort(1));
      });

      test('animated_lossy', () async {
        final anim = await decodeWebPFile(
          'test/_data/webp/animated_lossy.webp',
        );
        expect(anim, isNotNull);
        for (final frame in anim!.frames) {
          await encodeWebPFile(
            '$testOutputPath/webp/animated_lossy_${frame.frameIndex}.webp',
            frame,
          );
        }
      });

      // Regression: lossless webp with subtractGreen transform decoded as blank
      test('lossless with subtractGreen transform', () async {
        final image = await decodeWebPFile(
          'test/_data/webp/test_animated.webp',
        );
        expect(image, isNotNull);

        var hasVisiblePixel = false;
        for (final pixel in image!) {
          if (pixel.a > 0 && (pixel.r > 0 || pixel.g > 0 || pixel.b > 0)) {
            hasVisiblePixel = true;
            break;
          }
        }
        expect(
          hasVisiblePixel,
          isTrue,
          reason: 'VP8L lossless decoding produced blank image',
        );
      });

      final dir = Directory('test/_data/webp');
      final files = dir.listSync();
      group('getInfo', () {
        for (var f in files.whereType<File>()) {
          if (!f.path.endsWith('.webp')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final List<int> bytes = f.readAsBytesSync();

            final webp = WebPDecoder(bytes);
            final data = webp.info;
            if (data == null) {
              throw ImageException('Unable to parse WebP info: $name.');
            }

            if (_webpTests.containsKey(name)) {
              expect(data.format, equals(_webpTests[name]!['format']));
              expect(data.width, equals(_webpTests[name]!['width']));
              expect(data.height, equals(_webpTests[name]!['height']));
              expect(data.hasAlpha, equals(_webpTests[name]!['hasAlpha']));
              expect(
                data.hasAnimation,
                equals(_webpTests[name]!['hasAnimation']),
              );

              if (data.hasAnimation) {
                expect(
                  webp.numFrames(),
                  equals(_webpTests[name]!['numFrames']),
                );
              }
            }
          });
        }
      });

      group('decode', () {
        test('validate', () {
          var bytes = File('test/_data/webp/2b.webp').readAsBytesSync();
          final image = WebPDecoder().decode(bytes)!;
          final webpBytes = encodeWebP(image);
          File('$testOutputPath/webp/decode.webp')
            ..createSync(recursive: true)
            ..writeAsBytesSync(webpBytes);

          // Validate decoding.
          bytes = File('test/_data/webp/2b.png').readAsBytesSync();
          final debugImage = PngDecoder().decode(bytes)!;

          testImageEquals(image, debugImage);
        });

        for (var f in files) {
          if (f is! File || !f.path.endsWith('.webp')) {
            continue;
          }

          final name = f.uri.pathSegments.last;
          test(name, () {
            final List<int> bytes = f.readAsBytesSync();
            final image = WebPDecoder().decode(bytes);
            if (image == null) {
              throw ImageException('Unable to decode WebP Image: $name.');
            }

            final webpBytes = encodeWebP(image);
            File('$testOutputPath/webp/$name.webp')
              ..createSync(recursive: true)
              ..writeAsBytesSync(webpBytes);
          });
        }
      });

      group('decode animation', () {
        test('transparent animation', () {
          const path = 'test/_data/webp/animated_transparency.webp';
          final bytes = File(path).readAsBytesSync();
          final anim = WebPDecoder().decode(bytes)!;

          expect(anim.numFrames, equals(20));

          for (var i = 0; i < anim.numFrames; ++i) {
            final image = anim.getFrame(i);
            File('$testOutputPath/webp/animated_transparency_$i.webp')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodeWebP(image));
          }
          expect(anim.getFrame(2).getPixel(0, 0), equals([0, 0, 0, 0]));
        });
      });

      group('encode', () {
        test('round-trip lossless', () {
          // Decode a lossless webp, encode it, decode again, compare.
          final bytes =
              File('test/_data/webp/1_webp_ll.webp').readAsBytesSync();
          final original = WebPDecoder().decode(bytes)!;

          final encoded = encodeWebP(original);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(original.width));
          expect(decoded.height, equals(original.height));

          // Pixel-exact comparison
          for (var y = 0; y < original.height; y++) {
            for (var x = 0; x < original.width; x++) {
              final op = original.getPixel(x, y);
              final dp = decoded.getPixel(x, y);
              expect(dp.r, equals(op.r), reason: 'R mismatch at ($x,$y)');
              expect(dp.g, equals(op.g), reason: 'G mismatch at ($x,$y)');
              expect(dp.b, equals(op.b), reason: 'B mismatch at ($x,$y)');
              expect(dp.a, equals(op.a), reason: 'A mismatch at ($x,$y)');
            }
          }
        });

        test('encode rgb image', () {
          // Create a simple 3-channel image and encode it.
          final image = Image(width: 4, height: 4, numChannels: 3);
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              image.getPixel(x, y)
                ..r = (x * 60)
                ..g = (y * 60)
                ..b = 128;
            }
          }

          final encoded = encodeWebP(image);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(4));
          expect(decoded.height, equals(4));

          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final dp = decoded.getPixel(x, y);
              expect(dp.r.toInt(), equals(x * 60));
              expect(dp.g.toInt(), equals(y * 60));
              expect(dp.b.toInt(), equals(128));
              expect(dp.a.toInt(), equals(255));
            }
          }
        });

        test('encode rgba image with alpha', () {
          // Create a 4-channel image with varying alpha.
          final image = Image(width: 4, height: 4, numChannels: 4);
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              image.getPixel(x, y)
                ..r = 100
                ..g = 150
                ..b = 200
                ..a = (x + y * 4) * 16; // 0, 16, 32, ...
            }
          }

          final encoded = encodeWebP(image);
          final decoded = WebPDecoder().decode(encoded);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(4));
          expect(decoded.height, equals(4));

          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final dp = decoded.getPixel(x, y);
              expect(dp.r.toInt(), equals(100));
              expect(dp.g.toInt(), equals(150));
              expect(dp.b.toInt(), equals(200));
              expect(dp.a.toInt(), equals((x + y * 4) * 16));
            }
          }
        });

        test('encodeWebPFile', () async {
          final image = Image(width: 2, height: 2, numChannels: 4);
          image.getPixel(0, 0)
            ..r = 255
            ..g = 0
            ..b = 0
            ..a = 255;
          image.getPixel(1, 0)
            ..r = 0
            ..g = 255
            ..b = 0
            ..a = 128;
          image.getPixel(0, 1)
            ..r = 0
            ..g = 0
            ..b = 255
            ..a = 64;
          image.getPixel(1, 1)
            ..r = 255
            ..g = 255
            ..b = 0
            ..a = 0;

          final filePath = '$testOutputPath/webp/encode_test.webp';
          File(filePath).parent.createSync(recursive: true);
          await encodeWebPFile(filePath, image);
          expect(File(filePath).existsSync(), isTrue);

          final readBack = File(filePath).readAsBytesSync();
          final decoded = WebPDecoder().decode(readBack);
          expect(decoded, isNotNull);
          expect(decoded!.width, equals(2));
          expect(decoded.height, equals(2));
          expect(decoded.getPixel(0, 0).r.toInt(), equals(255));
          expect(decoded.getPixel(1, 0).g.toInt(), equals(255));
          expect(decoded.getPixel(0, 1).b.toInt(), equals(255));
          expect(decoded.getPixel(1, 1).a.toInt(), equals(0));
        });
      });
    });
  });
}

const _webpTests = {
  '1.webp': {
    'format': WebPFormat.lossy,
    'width': 550,
    'height': 368,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '1_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '1_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '2.webp': {
    'format': WebPFormat.lossy,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '2b.webp': {
    'format': WebPFormat.lossy,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '2_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '2_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '3.webp': {
    'format': WebPFormat.lossy,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '3_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '3_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '4.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '4_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '4_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '5.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  '5_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  '5_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false,
  },
  'BladeRunner.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75,
  },
  'BladeRunner_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75,
  },
  'red.webp': {
    'format': WebPFormat.lossy,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false,
  },
  'SteamEngine.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31,
  },
  'SteamEngine_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31,
  },
};
