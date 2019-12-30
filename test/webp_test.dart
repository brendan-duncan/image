import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  var dir = Directory('test/res/webp');
  var files = dir.listSync();

  group('WebP/getInfo', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.webp')) {
        continue;
      }

      var name = f.path.split(RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = (f as File).readAsBytesSync();

        var data = WebPDecoder().startDecode(bytes);
        if (data == null) {
          throw ImageException('Unable to parse WebP info: $name.');
        }

        if (_webp_tests.containsKey(name)) {
          expect(data.format, equals(_webp_tests[name]['format']));
          expect(data.width, equals(_webp_tests[name]['width']));
          expect(data.height, equals(_webp_tests[name]['height']));
          expect(data.hasAlpha, equals(_webp_tests[name]['hasAlpha']));
          expect(data.hasAnimation, equals(_webp_tests[name]['hasAnimation']));

          if (data.hasAnimation) {
            var anim = WebPDecoder().decodeAnimation(bytes);
            expect(anim.length, equals(_webp_tests[name]['numFrames']));
          }
        }
      });
    }
  });

  group('WebP/decodeImage', () {
    test('validate', () {
      var file = File('test/res/webp/2b.webp');
      var bytes = file.readAsBytesSync();
      var image = WebPDecoder().decodeImage(bytes);
      var png = PngEncoder().encodeImage(image);
      File('.dart_tool/out/webp/decode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      // Validate decoding.
      file = File('test/res/webp/2b.png');
      bytes = file.readAsBytesSync();
      var debugImage = PngDecoder().decodeImage(bytes);
      var found = false;
      for (var y = 0; y < debugImage.height && !found; ++y) {
        for (var x = 0; x < debugImage.width; ++x) {
          var dc = debugImage.getPixel(x, y);
          var c = image.getPixel(x, y);
          expect(c, equals(dc));
        }
      }
    });

    for (var f in files) {
      if (f is! File || !f.path.endsWith('.webp')) {
        continue;
      }

      var name = f.path.split(RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        var image = WebPDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode WebP Image: $name.');
        }

        var png = PngEncoder().encodeImage(image);
        File('.dart_tool/out/webp/${name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }
  });
}

const _webp_tests = {
  '1.webp': {
    'format': 1,
    'width': 550,
    'height': 368,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '1_webp_a.webp': {
    'format': 1,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '1_webp_ll.webp': {
    'format': 2,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2.webp': {
    'format': 1,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2b.webp': {
    'format': 1,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2_webp_a.webp': {
    'format': 1,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2_webp_ll.webp': {
    'format': 2,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3.webp': {
    'format': 1,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '3_webp_a.webp': {
    'format': 1,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3_webp_ll.webp': {
    'format': 2,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4.webp': {
    'format': 1,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '4_webp_a.webp': {
    'format': 1,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4_webp_ll.webp': {
    'format': 2,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5.webp': {
    'format': 1,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '5_webp_a.webp': {
    'format': 1,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5_webp_ll.webp': {
    'format': 2,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  'BladeRunner.webp': {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'BladeRunner_lossy.webp': {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'red.webp': {
    'format': 1,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false
  },
  'SteamEngine.webp': {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  },
  'SteamEngine_lossy.webp': {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  }
};
