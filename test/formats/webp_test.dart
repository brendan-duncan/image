import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void webpTest() {
  const path = 'test/_data/webp';
  group('webp', () {
    group('decode lossless', () {
      const name = 'test';
      test('$name.webp', () {
        final webp = decodeWebP(File('$path/$name.webp').readAsBytesSync())!;
        final png = decodePng(File('$path/$name.png').readAsBytesSync())!;
        File('$testOutputPath/webp/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(PngEncoder().encodeImage(webp));
        testImageEquals(webp, png);
      });
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
                data.hasAnimation, equals(_webpTests[name]!['hasAnimation']));

            if (data.hasAnimation) {
              expect(webp.numFrames(), equals(_webpTests[name]!['numFrames']));
            }
          }
        });
      }
    });

    group('decode', () {
      test('validate', () {
        var bytes = File('test/_data/webp/2b.webp').readAsBytesSync();
        final image = WebPDecoder().decodeImage(bytes)!;
        final png = PngEncoder().encodeImage(image);
        File('$testOutputPath/webp/decode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        // Validate decoding.
        bytes = File('test/_data/webp/2b.png').readAsBytesSync();
        final debugImage = PngDecoder().decodeImage(bytes)!;

        testImageEquals(image, debugImage);
      });

      for (var f in files) {
        if (f is! File || !f.path.endsWith('.webp')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final List<int> bytes = f.readAsBytesSync();
          final image = WebPDecoder().decodeImage(bytes);
          if (image == null) {
            throw ImageException('Unable to decode WebP Image: $name.');
          }

          final png = PngEncoder().encodeImage(image);
          File('$testOutputPath/webp/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
        });
      }
    });

    group('decode animation', () {
      test('transparent animation', () {
        const path = 'test/_data/webp/animated_transparency.webp';
        final bytes = File(path).readAsBytesSync();
        final anim = WebPDecoder().decodeAnimation(bytes)!;

        expect(anim.numFrames, equals(20));
        expect(anim.frames[2].getPixel(0, 0), equals([0, 0, 0]));

        for (var i = 0; i < anim.numFrames; ++i) {
          final image = anim.frames[i];
          File('$testOutputPath/webp/animated_transparency_$i.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(PngEncoder().encodeImage(image));
        }
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
    'hasAnimation': false
  },
  '1_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '1_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2.webp': {
    'format': WebPFormat.lossy,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2b.webp': {
    'format': WebPFormat.lossy,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3.webp': {
    'format': WebPFormat.lossy,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '3_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '4_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5.webp': {
    'format': WebPFormat.lossy,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '5_webp_a.webp': {
    'format': WebPFormat.lossy,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5_webp_ll.webp': {
    'format': WebPFormat.lossless,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  'BladeRunner.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'BladeRunner_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'red.webp': {
    'format': WebPFormat.lossy,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false
  },
  'SteamEngine.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  },
  'SteamEngine_lossy.webp': {
    'format': WebPFormat.animated,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  }
};
